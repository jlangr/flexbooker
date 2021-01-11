require 'net/http'
require 'json'

class Flexbooker
  def retrieve_sessions(service_id, bearer_token="")
    get("https://merchant-api.flexbooker.com/api/CalendarFeed?start=#{days_out(0)}&end=#{days_out(180)}&serviceIds=#{service_id}", bearer_token)
  end

  # test abstraction in TDD: 39117
  #  TDD paint by numbers: 38420
  # Mob composing: 39116
  # Legacy: 39115

  def post_schedule(bearer_token="")
    schedule = {
      "employeeId" => 37789,
      "secondEmployeeId" => nil,
      "services" => [{ "serviceId" => 39115 }],
      "bufferTimeInMinutes" => 0,
      "startDate" => "2021-02-02",
      "recurs" => false,
      "availableDays": [{ "date": "2021-02-02", "hours": [{ "startTime": "3:30 PM" }]}],
      "scheduleType" => 1,
      "slots" => 6
    }
    post("https://merchant-api.flexbooker.com/Schedule", bearer_token, schedule)
  end

  # TODO redundancies between this and put and get
  def post(url, bearer_token, obj)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      request = Net::HTTP::Post.new uri
      request['Authorization'] = "Bearer #{bearer_token}"
      request['Content-Type'] = 'application/json'
      request.body = obj.to_json

      response = http.request request
      # TODO if response.code not successful
      puts response.code
      puts response.body
    end
  end

  def put(url, bearer_token, obj)
    uri = URI(url)
#    puts uri
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      request = Net::HTTP::Put.new uri
      request['Authorization'] = "Bearer #{bearer_token}"
      request['Content-Type'] = 'application/json'
      request.body = obj.to_json

      response = http.request request
      # TODO if response.code not successful
      puts response.code
      puts response.body

#      body = response.body
#      puts "#{body}"
#      JSON.parse(body)
    end
  end

  def get(url, bearer_token)
    uri = URI(url)
#    puts uri
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      request = Net::HTTP::Get.new uri
      request['Authorization'] = "Bearer #{bearer_token}"
      request['accept'] = "application/json"

      response = http.request request
      # TODO if response.code not successful

      body = response.body
#      puts "#{body}"
      JSON.parse(body)
    end
  end

  def days_out(days)
    (Date.today + days).to_s
  end
end
