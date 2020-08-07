require './upcoming_dates.rb'

describe "retrieve start time from services" do
  before(:each) do
    @updater = UpcomingDates.new
  end

  # shit what about time zone

  it "does stuff" do

    schedules = [
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

    expect(@updater.start_times(99999, schedules)).to eql(["2020-07-31T17:00Z"])

  end
end

describe "service id from lines" do
  before(:each) do
    @updater = UpcomingDates.new
  end

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
