class Flexbooker
  def retrieve_sessions(service_id)

    # TODO: end date 6 months out
    uri = URI("https://merchant-api.flexbooker.com/api/CalendarFeed?start=2020-09-04&end=2021-03-04&serviceIds=#{service_id}")

    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      request = Net::HTTP::Get.new uri
      request['Authorization'] = "Bearer #{@bearer_token}"
      request['accept'] = "application/json"

      response = http.request request

      body = response.body
      JSON.parse(body)
    end
  end
end
