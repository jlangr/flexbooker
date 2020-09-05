require 'json'
require 'net/http'
require 'time'
require 'active_support/time'
require './flexbooker'

PUBMOB_ROOT="/Users/jlangr/pubmob"
OFFERINGS_DIR = "#{PUBMOB_ROOT}/_offerings"
TIME_ZONE_FOR_FLEXBOOKER_DATES="America/Denver"

class Stdout
  def log(s)
    puts s
  end
end

class NextAvailableDates
  attr_accessor :sessions, :json_string, :sessions_json_string, :bearer_token

  def initialize(flexbooker: Flexbooker.new, io: Stdout.new)
    @io = io
    @flexbooker = flexbooker
  end

  def upcoming_start_times(service_id)
    sessions = @flexbooker.retrieve_sessions(service_id, @bearer_token)
# if service_id == "39115"
#   puts "\t#{sessions}"
# end
    sessions.collect {| session | start_time(session) }
  end

  def start_time(session)
    timestamp_mountain = session["start"]
    start_time_utc = time_string_mst_to_utc_0(timestamp_mountain)
    start_time_utc.strftime('%FT%RZ')
  end

  def time_string_mst_to_utc_0(time_string)
    start_time_date = Time.parse(time_string)
    Time.use_zone(TIME_ZONE_FOR_FLEXBOOKER_DATES) { Time.zone.local_to_utc(start_time_date)   }
  end

  def flexbooker_service_id(filename, lines)
    line = lines.detect {| line | property(line) == "booking-link" }
    if not line
      @io.log "#{filename}: no booking-link property"
      return nil 
    end
    match = value(line).match(/.*serviceIds=(\d+)/)
    if not match
      @io.log "#{filename}: no serviceIds query param on the booking-link property"
      return nil
    end
    match.captures[0]
  end

  def update_files()
    Dir.foreach("#{OFFERINGS_DIR}") {|filename| update_file(filename) if markdown_file? filename }
  end

  def markdown_file?(filename)
    (not filename == '.') and (not filename == '..') and filename.end_with? '.md'
  end

  def update_file(filename)
    full_filename = "#{OFFERINGS_DIR}/#{filename}"
    lines = IO.readlines(full_filename, chomp: true)
    @io.log "updating #{filename}"
    updated_lines = update_start_times(filename, lines)
    if updated_lines and not updated_lines == lines
      puts "\tupdated!"
      write(full_filename, updated_lines) 
    end
  end

  def write(full_filename, updated_lines)
    File.open(full_filename, "w") {|f| f.write(updated_lines.join("\n")) }
  end

  #TODO do nothing if booking line not updated

  def update_start_times(filename, lines)
    service_id = flexbooker_service_id(filename, lines)
    return nil if not service_id

#return nil if not service_id == "39115"

    start_times = upcoming_start_times(service_id)
    lines.collect{| line | update_if_next_available_sessions(line, start_times) }
  end

  def update_if_next_available_sessions(line, start_times)
    property(line) == "next-available-sessions" ?  next_available_sessions_line(line, start_times) : line
  end

  def quoted(array)
    array.collect{| each | "\"#{each}\"" }
  end

  def next_available_sessions_line(line, start_times)
    updated_line = "next-available-sessions: [#{comma_separated(quoted(start_times))}]"
    updated_line == line ? line : updated_line
  end

  def comma_separated(string_array)
    string_array.compact.reject(&:empty?).join(',')
  end

  def property(line)
    index = line.index(':')
    return "" if not index
    line[0..index - 1].strip
  end

  def value(line)
    line[(line.index(':') + 1)..line.length]
  end
end

