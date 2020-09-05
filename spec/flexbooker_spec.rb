require './flexbooker.rb'

describe "flexbooker" do
  it "calculates six months out for search date span" do
    allow(Date).to receive(:today).and_return Date.new(2030,1,1)

    expect(Flexbooker.new.days_out(180)).to eql("2030-06-30")
  end
end
