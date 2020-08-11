require 'json'
require 'net/http'
require 'date'

PUBMOB_ROOT="/Users/jlangr/pubmob"
TIME_OFFSET_FOR_FLEXBOOKER_DATES="-07:00"

class UpcomingDates

  attr_accessor :schedules, :account, :json_string

  def start_times(service_id)
    matching_schedules(service_id)
      .collect {| schedule | available_days(schedule) }
      .flatten
  end

  def available_days(schedule)
    schedule["availableDays"]
      .reject {| day | day["date"].nil? }
      .collect {| day | start_time(day) }
      .reject {| start_time | is_past? start_time }
  end

  def matching_schedules(service_id)
    @schedules.select { | each | sole_service_matches_service_id? each, service_id }
  end

  def sole_service_matches_service_id?(schedule, service_id)
    service = schedule["services"][0] # assume only one service ID to a schedule for now?
    service["serviceId"] == service_id.to_i
  end

  def is_past?(time_string)
    DateTime.parse(time_string) < DateTime.now
  end

  # TODO: update based on what we learn about times in Flexbooker
  def start_time(day)
    session_date = day["date"]
    start_time = day["hours"][0]["startTime"]
    
    start_time_string_in_mst = "#{session_date}T#{start_time}#{TIME_OFFSET_FOR_FLEXBOOKER_DATES}"

    start_time_date = DateTime.parse(start_time_string_in_mst)
    start_time_utc = start_time_date.new_offset('-0000')
    start_time_utc.strftime('%FT%RZ')
  end

  def flexbooker_service_id(lines)
    line = lines.detect {| line | property(line) == "booking-link" }
    raise "no booking-link property" if not line
    match = value(line).match(/.*serviceIds=(\d+)/)
    raise "no serviceIds query param on the booking-link property" if not match
    match.captures[0]
  end

  def update_files()
    dir = "#{PUBMOB_ROOT}/_offerings"
    Dir.foreach("#{dir}") do |filename|
      next if filename == '.' or filename == '..' or (not filename.end_with? '.md')
      full_filename = "#{dir}/#{filename}"
      lines = IO.readlines(full_filename, chomp: true)
      updated_lines = update_start_times(lines)
      File.open(full_filename, "w") { |f| f.write(updated_lines.join("\n")) }
    end
  end

  def update_start_times(lines)
    service_id = flexbooker_service_id(lines)
    start_times = start_times(service_id)
    lines.collect do | line |
      if property(line) == "next-available-sessions" 
        "next-available-sessions: [#{comma_separated(start_times)}]"
      else 
        line 
      end
    end
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
    @account = json
    @services = json["services"]
    @schedules = json["schedules"]
  end
end

