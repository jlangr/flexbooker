require './upcoming_dates.rb'

describe "everything" do
  before(:each) do
    @updater = UpcomingDates.new
  end

  describe "retrieve start time from services" do

    # uh oh what about time zone

    it "extracts single start time" do

      @updater.schedules = [
        {"id"=>12345, 
         "services"=>[{"serviceId"=>99999, "price"=>95}], 
         "startDate"=>"7/31/2020", "endDate"=>"7/31/2020", 
         "availableDays"=>[{"day"=>nil, "hours"=>[{"startTime"=>"17:00", "endTime"=>"18:15"}], "date"=>"2020-07-31"}], 
         "scheduleType"=>1, "slots"=>6},
        {"id"=>54321, 
         "services"=>[{"serviceId"=>88888, "price"=>95}], 
         "startDate"=>"8/29/2020", "endDate"=>"8/29/2020", 
         "availableDays"=>[{"day"=>nil, "hours"=>[{"startTime"=>"11:10", "endTime"=>"12:25"}], "date"=>"2020-08-29"}], 
         "scheduleType"=>1, "slots"=>6}]

      expect(@updater.start_times(99999)).to eql(["2020-07-31T17:00Z"])
      expect(@updater.start_times(88888)).to eql(["2020-08-29T11:10Z"])

    end
  end

  describe "comma_separated" do
    it "comma-separates an array of strings" do
      expect(@updater.comma_separated(["a", "b"])).to eql("a,b")
      expect(@updater.comma_separated([])).to eql("")
    end
  end

  it "extracts multiple dates from availableDays" do
    @updater.schedules = [{
      "id"=> 76816,
      "employeeId"=> 38319,
      "services"=> [{ "serviceId"=> 39113, "price"=> 95 }],
      "startDate"=> "8/6/2020", "endDate"=> "8/6/2020",
      "availableDays"=> [{
          "hours"=> [{ "startTime"=> "09:30", "endTime"=> "10:45" }],
          "date"=> "2020-08-20" },
        { "hours"=> [{ "startTime"=> "09:30", "endTime"=> "10:45" }],
          "date"=> "2020-09-03" }
      ]
    }]

    expect(@updater.start_times(39113))
      .to eql(["2020-08-20T09:30Z", "2020-09-03T09:30Z"])
  end

  # TODO: sort by date; remove any that have past; limit to 3; updates (overwrites) existing
  # TODO: what if there are no entries in schedules

  describe "update_start_times" do
    it "updates the _offerings markdown lines with appropriate next start times" do
      @updater.schedules = [
        {"services"=> [{ "serviceId" => 12345 }], 
         "availableDays" => [{"hours" => [{ "startTime" => "17:00" }], "date" => "2020-07-31"},
                             {"hours" => [{ "startTime" => "19:00" }], "date" => "2020-08-02"}]}]
      lines = ["next-available-sessions: []", 
               "booking-link: \"https://a.flexbooker.com/blah?serviceIds=12345\""]

      updated_lines = @updater.update_start_times(lines)

      expect(updated_lines[0]).to eql("next-available-sessions: [2020-07-31T17:00Z,2020-08-02T19:00Z]")
    end

    it "empties the available session if no times exist" do
      @updater.schedules = []
      lines = ["next-available-sessions: []", 
               "booking-link: \"https://a.flexbooker.com/blah?serviceIds=12345\""]

      updated_lines = @updater.update_start_times(lines)

      expect(updated_lines[0]).to eql("next-available-sessions: []")
    end
  end

  describe "service id from lines" do
    it "returns serviceIds query parm value from booking-link property" do
      lines = [
        "---",
        "pagename: offering",
        "next-available-sessions: []",
        "summary-blurb-80-words: \"<p>some blurb</p>\"",
        "booking-link: \"https://a.flexbooker.com/widget/75e809c1-6688-42cc-9fbf-77b001c15991?serviceIds=54321\"",
        "active: true",
        "---"]

      service_id = @updater.flexbooker_service_id(lines)

      expect(service_id).to eql("54321")
    end

    it "can deal with whitespace around the property name" do
      lines = ["   booking-link : \"https://x.com?serviceIds=12345\"",]

      service_id = @updater.flexbooker_service_id(lines)

      expect(service_id).to eql("12345")
    end

    it "needs the booking-link property" do
      linesWithoutBookingLink = ["pagename: whatever"]

      expect{ @updater.flexbooker_service_id(linesWithoutBookingLink) }
        .to raise_error("no booking-link property")
    end

    it "needs a valid URL for the booking-link property" do
      linesWithoutServiceIds = ["booking-link: \"https://a.flexbooker.com/widget/75e809c1-6688-42cc-9fbf-77b001c15991\""]

      expect{ @updater.flexbooker_service_id(linesWithoutServiceIds) }
        .to raise_error("no serviceIds query param on the booking-link property")
    end
  end
end
