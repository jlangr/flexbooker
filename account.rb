require './upcoming_dates.rb'

authorizationToken = ARGV[0]
updater = UpcomingDates.new
updater.loadAccount(authorizationToken)
puts updater.json_string
