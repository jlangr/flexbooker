require './next_available_dates.rb'

class IOStub
  def log(s) end
end

describe "" do
  before(:each) do
    @updater = NextAvailableDates.new(flexbooker: @flexbooker, io: IOStub.new)
  end

  # MST = UTC - 7 (American/Denver)
  # MDT = UTC - 6 (American/Denver)

  describe "retrieving start time from services" do
    it "extracts start times" do
      @flexbooker = object_double(Flexbooker.new, :retrieve_sessions => 
          [{
            "title": "Call Your Shot TDD (0/6) (James Grenning)",
            "start": "2035-09-11T09:30:00.0000000",
            "resourceId": 38320,
          },
          {
            "title": "Another class (0/6) (James Grenning)",
            "start": "2035-09-18T08:00:00.0000000",
            "resourceId": 38320,
          }])
      @updater = NextAvailableDates.new(flexbooker: @flexbooker, io: IOStub.new)
      expect(@updater.upcoming_start_times(39118)).to eql(["2035-09-11T15:30Z", "2035-09-18T14:00Z"])
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
