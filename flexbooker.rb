class Flexbooker
  def retrieve_sessions(service_id, bearer_token="")
    get("https://merchant-api.flexbooker.com/api/CalendarFeed?start=#{days_out(0)}&end=#{days_out(180)}&serviceIds=#{service_id}", bearer_token)
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
