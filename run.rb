require './upcoming_dates.rb'

authorizationToken = ARGV[0]
updater = UpcomingDates.new
updater.loadAccount(authorizationToken)
start_times = updater.start_times(39115, updater.schedules)
puts "start times: #{start_times}" 
