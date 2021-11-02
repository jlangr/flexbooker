require 'net/http'
require 'json'

class Flexbooker
  def retrieve_sessions(service_id, bearer_token="")
    get("https://merchant-api.flexbooker.com/api/CalendarFeed?start=#{days_out(0)}&end=#{days_out(180)}&serviceIds=#{service_id}", bearer_token)
  end

  # test abstraction in TDD: 39117
  #  TDD paint by numbers: 38420
  # Mob composing: 39116 (6)
  # Legacy: 39115
  #
  # Jeff 37789

  def post_schedule(bearer_token="")
    employee=37789
    # post_one(bearer_token, employee, "2021-07-06", "3:30 PM", 38420)
    # post_one(bearer_token, employee, "2021-07-13", "3:30 PM", 38420)
    # post_one(bearer_token, employee, "2021-07-20", "3:30 PM", 39115)
    # post_one(bearer_token, employee, "2021-07-27", "3:30 PM", 39115)
    # post_one(bearer_token, employee, "2021-08-03", "3:30 PM", 38420)
    # post_one(bearer_token, employee, "2021-08-10", "3:30 PM", 38420)
    # post_one(bearer_token, employee, "2021-08-17", "3:30 PM", 39115)
    # post_one(bearer_token, employee, "2021-08-24", "3:30 PM", 39115)
    post_one(bearer_token, employee, "2021-09-28", "3:30 PM", 39116)
    post_one(bearer_token, employee, "2021-10-12", "3:30 PM", 39115)
    post_one(bearer_token, employee, "2021-10-19", "3:30 PM", 38420)
    post_one(bearer_token, employee, "2021-10-26", "3:30 PM", 39116)
    post_one(bearer_token, employee, "2021-11-02", "3:30 PM", 39115)
    post_one(bearer_token, employee, "2021-11-09", "3:30 PM", 38420)
    post_one(bearer_token, employee, "2021-11-16", "3:30 PM", 39116)
    post_one(bearer_token, employee, "2021-11-23", "3:30 PM", 39115)
    post_one(bearer_token, employee, "2021-11-30", "3:30 PM", 38420)
  end

  def post_one( bearer_token, employee, date, time, session, slots=6)
    schedule = {
      "employeeId" => employee,
      "secondEmployeeId" => nil,
      "services" => [{ "serviceId" => session }],
      "bufferTimeInMinutes" => 0,
      "startDate" => date,
      "recurs" => false,
      "availableDays": [{ "date": date, "hours": [{ "startTime": time }]}],
      "scheduleType" => 1,
      "slots" => slots
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
