require 'json'
require 'net/http'
require 'time'
require 'active_support/time'

PUBMOB_ROOT="/Users/jlangr/pubmob"
OFFERINGS_DIR = "#{PUBMOB_ROOT}/_offerings"
TIME_ZONE_FOR_FLEXBOOKER_DATES="America/Denver"

class Stdout
  def log(s)
    puts s
  end
end

class UpcomingDates
  attr_accessor :schedules, :json_string

  def initialize(io: Stdout.new)
    @io = io
  end

  def matching_schedules(service_id)
    @schedules.select {| each | sole_service_matches_service_id? each, service_id }
  end

  def sole_service_matches_service_id?(schedule, service_id)
    service = schedule["services"][0] # assume only one service ID to a schedule for now?
    service["serviceId"] == service_id.to_i
  end

  def is_past?(time_string)
    Time.parse(time_string) < Time.now
  end

  def start_times(service_id)
    matching_schedules(service_id)
      .collect {| schedule | available_days(schedule) }
      .flatten
  end

  def available_days(schedule)
    schedule["availableDays"]
      .reject {| available_day | available_day["date"].nil? }
      .collect {| available_day | start_time(start_date_and_time_from_available_day(available_day)) }
      .reject {| start_time | is_past? start_time }
  end

  def start_time((start_date, start_time))
    start_time_utc = time_string_mst_to_utc_0(to_utc_format_string(start_date, start_time))
    start_time_utc.strftime('%FT%RZ')
  end

  def start_date_and_time_from_available_day(available_day)
    [available_day["date"], 
     available_day["hours"][0]["startTime"]]
  end

  def time_string_mst_to_utc_0(time_string)
    start_time_date = Time.parse(time_string)
    Time.use_zone(TIME_ZONE_FOR_FLEXBOOKER_DATES) { Time.zone.local_to_utc(start_time_date)   }
  end

  def to_utc_format_string(date, time)
    "#{date}T#{time}"
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
    write(full_filename, updated_lines) if updated_lines
  end

  def write(full_filename, updated_lines)
    File.open(full_filename, "w") {|f| f.write(updated_lines.join("\n")) }
  end

  def update_start_times(filename, lines)
    service_id = flexbooker_service_id(filename, lines)
    return nil if not service_id
    start_times = start_times(service_id)
    lines.collect{| line | update_if_next_available_sessions(line, start_times) }
  end

  def update_if_next_available_sessions(line, start_times)
    property(line) == "next-available-sessions" ?  next_available_sessions_line(start_times) : line
  end

  def next_available_sessions_line(start_times)
    "next-available-sessions: [#{comma_separated(start_times)}]"
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

  def loadAccount(authorizationToken)
    uri = URI('https://merchant-api.flexbooker.com/Account')
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{authorizationToken}"
    request['accept'] = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http| http.request(request) }

    body = response.body
    @json_string = body
    json = JSON.parse(body)
    @schedules = json["schedules"]
  end
end

