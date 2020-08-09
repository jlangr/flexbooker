require './upcoming_dates.rb'

describe "everything" do
  before(:each) do
    @updater = UpcomingDates.new
  end

  describe "retrieve start time from services" do

    # TODO time zone. Right now it defaults to assuming UTC.
    #                 Flexbooker will possibly fix so that
    #                 things will be entered in the calendar time
    #                 set by the "employee." Fix after we see that change.

    it "extracts single start time" do

      @updater.schedules = [
        {"id"=>12345, 
         "services"=>[{"serviceId"=>99999, "price"=>95}], 
         "startDate"=>"7/31/2035", "endDate"=>"7/31/2035", 
         "availableDays"=>[{"day"=>nil, "hours"=>[{"startTime"=>"17:00", "endTime"=>"18:15"}], "date"=>"2035-07-31"}], 
         "scheduleType"=>1, "slots"=>6},
        {"id"=>54321, 
         "services"=>[{"serviceId"=>88888, "price"=>95}], 
         "startDate"=>"8/29/2035", "endDate"=>"8/29/2035", 
         "availableDays"=>[{"day"=>nil, "hours"=>[{"startTime"=>"11:10", "endTime"=>"12:25"}], "date"=>"2035-08-29"}], 
         "scheduleType"=>1, "slots"=>6}]

      expect(@updater.start_times(99999)).to eql(["2035-07-31T17:00Z"])
      expect(@updater.start_times(88888)).to eql(["2035-08-29T11:10Z"])

    end

    it "comines multiple schedules" do

      @updater.schedules = [
        {"id"=>12345, 
         "services"=>[{"serviceId"=>99999, "price"=>95}], 
         "startDate"=>"7/31/2035", "endDate"=>"7/31/2035", 
         "availableDays"=>[{"day"=>nil, "hours"=>[{"startTime"=>"17:00", "endTime"=>"18:15"}], "date"=>"2035-07-31"}], 
         "scheduleType"=>1, "slots"=>6},
        {"id"=>54321, 
         "services"=>[{"serviceId"=>99999, "price"=>95}], 
         "startDate"=>"8/29/2035", "endDate"=>"8/29/2035", 
         "availableDays"=>[{"day"=>nil, "hours"=>[{"startTime"=>"11:10", "endTime"=>"12:25"}], "date"=>"2035-08-29"}], 
         "scheduleType"=>1, "slots"=>6}]

      expect(@updater.start_times(99999)).to eql(["2035-07-31T17:00Z","2035-08-29T11:10Z"])

    end

    it "extracts multiple dates from availableDays" do
      @updater.schedules = [{
        "id"=> 76816,
        "employeeId"=> 38319,
        "services"=> [{ "serviceId"=> 39113, "price"=> 95 }],
        "startDate"=> "8/6/2035", "endDate"=> "8/6/2035",
        "availableDays"=> [{
            "hours"=> [{ "startTime"=> "09:30", "endTime"=> "10:45" }],
            "date"=> "2035-08-20" },
          { "hours"=> [{ "startTime"=> "09:30", "endTime"=> "10:45" }],
            "date"=> "2035-09-03" }
        ]
      }]

      expect(@updater.start_times(39113))
        .to eql(["2035-08-20T09:30Z", "2035-09-03T09:30Z"])
    end

    it "ignores availableDays entries with null date" do
      @updater.schedules = [{
        "services"=> [{ "serviceId"=> 39113 }],
        "availableDays"=> [{
            "hours"=> [{ "startTime"=> "09:30", "endTime"=> "10:45" }],
            "date"=> nil },
          { "hours"=> [{ "startTime"=> "09:30", "endTime"=> "10:45" }],
            "date"=> "2035-09-03" } ] }]

      expect(@updater.start_times(39113)).to eql(["2035-09-03T09:30Z"])
    end

    it "returns empty array if no schedule exists for service ID" do
      @updater.schedules = []

      expect(@updater.start_times(99999)).to eql([])
    end

    it "ignores past offerings" do
      @updater.schedules = [
        {"services"=> [{ "serviceId" => 12345 }], 
         "availableDays" => [{"hours" => [{ "startTime" => "17:00" }], "date" => "2019-07-31"},
                             {"hours" => [{ "startTime" => "19:00" }], "date" => "2038-01-01"}]}]

      expect(@updater.start_times(12345)).to eql(["2038-01-01T19:00Z"])
    end
  end

  describe "update_start_times" do
    it "updates the _offerings markdown lines with appropriate next start times" do
      @updater.schedules = [
        {"services"=> [{ "serviceId" => 12345 }], 
         "availableDays" => [{"hours" => [{ "startTime" => "17:00" }], "date" => "2035-07-31"},
                             {"hours" => [{ "startTime" => "19:00" }], "date" => "2035-08-02"}]}]
      lines = ["next-available-sessions: []", 
               "booking-link: \"https://a.flexbooker.com/blah?serviceIds=12345\""]

      updated_lines = @updater.update_start_times(lines)

      expect(updated_lines[0]).to eql("next-available-sessions: [2035-07-31T17:00Z,2035-08-02T19:00Z]")
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

  describe "comma_separated" do
    it "comma-separates an array of strings" do
      expect(@updater.comma_separated(["a", "b"])).to eql("a,b")
      expect(@updater.comma_separated([])).to eql("")
    end
  end
end
