require './next_available_dates.rb'

updater = NextAvailableDates.new
updater.bearer_token = ARGV[0]
updater.update_files()
