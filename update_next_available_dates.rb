require './next_available_dates.rb'

authorizationToken = ARGV[0]
updater = NextAvailableDates.new
updater.loadStuff(authorizationToken)
#updater.update_files()
