require './next_available_dates.rb'

updater = NextAvailableDates.new
if ARGV.length < 2
  puts "must supply pubmob dir"
  puts "pubmob_dir set to #{ARGV[0]}"
else
  updater.bearer_token = ARGV[1]
  updater.pubmob_directory = ARGV[0]
  updater.update_files()
end
