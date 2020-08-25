require './upcoming_dates.rb'

class IOStub
  def log(s) end
end

describe "" do
  before(:each) do
    @updater = UpcomingDates.new(io: IOStub.new)
  end

  # MST = UTC - 7 (American/Denver)
  # MDT = UTC - 6 (American/Denver)

  describe("a start time") do
    it("is a UTC time string for MST times outside DST (UTC-7)") do
      expect(@updater.start_time(["2020-12-31", "12:00"])).to eql("2020-12-31T19:00Z")
    end

    it("is a UTC time string for MST times during DST (UTC-6)") do
      expect(@updater.start_time(["2020-08-13", "12:00"])).to eql("2020-08-13T18:00Z")
    end
  end

  describe "recurring events" do
    it "is a recurring event when any day in availableDays is not nil" do
      schedule =
        { "availableDays" => [
          { "day" => 1, "hours" => [{ "startTime"=> "12:00", "endTime" => "13:15" }], "date"=> nil },
          { "day"=> nil, "hours"=> [{ "startTime"=> "12:00", "endTime" => "13:15" }], "date"=> "2020-08-14" }]}

      expect(@updater.is_recurring_event? schedule).to be true
    end

    it "is not a recurring event when all days in availableDays are nil" do
      schedule =
        { "availableDays" => [
          { "day" => nil, "hours" => [{ "startTime"=> "12:00", "endTime" => "13:15" }], "date"=> nil },
          { "day"=> nil, "hours"=> [{ "startTime"=> "12:00", "endTime" => "13:15" }], "date"=> "2020-08-14" }]}

      expect(@updater.is_recurring_event? schedule).to be false
    end
  end

  describe "retrieving start time from services" do
    it "extracts single start time" do
      @updater.schedules = [
        { "services"=>[{"serviceId"=>99999}], 
          "availableDays"=>[{"hours"=>[{"startTime"=>"10:00", "endTime"=>"11:15"}], "date"=>"2035-12-31"}]},
        { "services"=>[{"serviceId"=>88888}], 
          "availableDays"=>[{"hours"=>[{"startTime"=>"04:10", "endTime"=>"05:25"}], "date"=>"2035-12-29"}]}]

      expect(@updater.start_times(99999)).to eql(["2035-12-31T17:00Z"])
      expect(@updater.start_times(88888)).to eql(["2035-12-29T11:10Z"])

    end

    it "combines multiple schedules" do
      @updater.schedules = [
        { "services"=>[{ "serviceId"=>99999 }], 
          "availableDays"=>[{"hours"=>[{"startTime"=>"10:00", "endTime"=>"11:15"}], "date"=>"2035-12-31"}], 
         "scheduleType"=>1, "slots"=>6},
        {
         "services"=>[{ "serviceId"=>99999 }], 
         "availableDays"=>[{"hours"=>[{"startTime"=>"04:10", "endTime"=>"05:25"}], "date"=>"2035-12-29"}]}]

      expect(@updater.start_times(99999)).to eql(["2035-12-31T17:00Z","2035-12-29T11:10Z"])
    end

    it "extracts multiple dates from availableDays" do
      @updater.schedules = [
        {"services"=> [{ "serviceId"=> 39113 }],
         "availableDays"=> [
           { "hours"=> [{ "startTime"=> "02:30", "endTime"=> "10:45" }],
           "date"=> "2035-12-20" },
           { "hours"=> [{ "startTime"=> "02:30", "endTime"=> "10:45" }],
           "date"=> "2035-12-03" }]}]
      expect(@updater.start_times(39113))
        .to eql(["2035-12-20T09:30Z", "2035-12-03T09:30Z"])
    end

    it "ignores availableDays entries for recurring event where day is nil" do
      @updater.schedules = [
        { "services"=> [{ "serviceId"=> 39113 }],
          "availableDays" => [
            { "day" => 1, "hours" => [{ "startTime"=> "12:00", "endTime" => "13:15" }], "date"=> nil },
            { "day" => nil, "hours"=> [{ "startTime"=> "12:00", "endTime" => "13:15" }], "date"=> "2035-01-01" }]} ]

      expect(@updater.start_times(39113)).to eql []
    end

    it "ignores availableDays entries with nil date" do
      @updater.schedules = [
        {"services"=> [{ "serviceId"=> 39113 }],
         "availableDays"=> [{
            "hours"=> [{ "startTime"=> "02:30", "endTime"=> "10:45" }],
            "date"=> nil },
          { "hours"=> [{ "startTime"=> "02:30", "endTime"=> "10:45" }],
            "date"=> "2035-12-03" }]}]

      expect(@updater.start_times(39113)).to eql(["2035-12-03T09:30Z"])
    end

    it "returns empty array if no schedule exists for service ID" do
      @updater.schedules = []

      expect(@updater.start_times(99999)).to eql([])
    end

    it "ignores past offerings" do
      @updater.schedules = [
        {"services"=> [{ "serviceId" => 12345 }], 
         "availableDays" => [{"hours" => [{ "startTime" => "17:00" }], "date" => "2019-07-31"},
                             {"hours" => [{ "startTime" => "12:00" }], "date" => "2038-01-01"}]}]

      expect(@updater.start_times(12345)).to eql(["2038-01-01T19:00Z"])
    end
  end

  describe "update_start_times" do
    it "updates the _offerings markdown lines with appropriate next start times" do
      @updater.schedules = [
        {"services"=> [{ "serviceId" => 12345 }], 
         "availableDays" => [{"hours" => [{ "startTime" => "10:00" }], "date" => "2035-12-31"},
                             {"hours" => [{ "startTime" => "12:00" }], "date" => "2035-12-02"}]}]
      lines = ["next-available-sessions: []", 
               "booking-link: \"https://a.flexbooker.com/blah?serviceIds=12345\""]

      updated_lines = @updater.update_start_times("", lines)

      expect(updated_lines[0]).to eql("next-available-sessions: [\"2035-12-31T17:00Z\",\"2035-12-02T19:00Z\"]")
    end

    it "returns nil when there's no booking line" do
      lines = []

      updated_lines = @updater.update_start_times("", lines)

      expect(updated_lines).to be_nil
    end

    it "returns nil when there's a problem getting the service ID" do
      lines = ["booking-link: \"\""]

      updated_lines = @updater.update_start_times("", lines)

      expect(updated_lines).to be_nil
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

      service_id = @updater.flexbooker_service_id("", lines)

      expect(service_id).to eql("54321")
    end

    it "can deal with whitespace around the property name" do
      lines = ["   booking-link : \"https://x.com?serviceIds=12345\"",]

      service_id = @updater.flexbooker_service_id("", lines)

      expect(service_id).to eql("12345")
    end

    it "needs the booking-link property" do
      linesWithoutBookingLink = ["pagename: whatever"]

      expect(@updater.flexbooker_service_id("", linesWithoutBookingLink))
        .to be_nil
    end

    it "needs a valid URL for the booking-link property" do
      linesWithoutServiceIds = ["booking-link: \"https://a.flexbooker.com/widget/75e809c1-6688-42cc-9fbf-77b001c15991\""]

      expect(@updater.flexbooker_service_id("", linesWithoutServiceIds))
        .to be_nil
    end
  end

  describe "comma_separated" do
    it "comma-separates an array of strings" do
      expect(@updater.comma_separated(["a", "b"])).to eql("a,b")
      expect(@updater.comma_separated([])).to eql("")
    end
  end
end
