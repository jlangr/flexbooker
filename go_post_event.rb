require './flexbooker.rb'

obj = Flexbooker.new
bearer_token = ARGV[0]
obj.post_schedule(bearer_token)
