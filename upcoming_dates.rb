require 'json'

require 'net/http'

class UpcomingDates

  #attr_reader :schedules

  def schedules
    @schedules
  end

  def load
    lines = File.readlines("/Users/jlangr/pubmob/_offerings/jefflangr-tdd-paint-by-numbers.md")
  end

  def start_times(serviceId, schedules)
    puts schedules
    schedule = schedules.detect {| schedule | schedule["services"][0]["serviceId"] == serviceId }
    available_days = schedule["availableDays"]
    # TODO allow more
    session_date = available_days[0]["date"]
    start_time = available_days[0]["hours"][0]["startTime"]
    # TODO convert from MST to zulu time
    ["#{session_date}T#{start_time}Z"]
  end

  def flexbooker_service_id(lines)
    line = lines.detect {| line | property(line) == "booking-link" }
    raise "no booking-link property" if not line
    match = value(line).match(/.*serviceIds=(\d+)/)
    raise "no serviceIds query param on the booking-link property" if not match
    match.captures[0]
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

    json = JSON.parse(body)
    @services = json["services"]
    @schedules = json["schedules"]
  end
end

