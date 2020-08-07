require './upcoming_dates.rb'

authorizationToken = ARGV[0]
updater = UpcomingDates.new
updater.loadAccount(authorizationToken)
#start_times = updater.start_times(39113, updater.schedules)
#puts "start times: #{start_times}" 

updater.update_files()
