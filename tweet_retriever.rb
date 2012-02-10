
$: << "."
require "oauth"
require "json"
# require "ap"
require "time"

require "lib/tweet_retriever"

config = TweetRetriever::Config.new("config.json")

# Initialize some variables
tweet_section = {}
#times_to_loop = 0
screen_name = config.screen_name

connect = TweetRetriever::Connect.new(config)

results_user = connect.get do |c|
	c.use_oauth true
	c.url "http://api.twitter.com/1/users/show.json?screen_name=" + screen_name
	c.get_json
end



# Exchange our oauth_token and oauth_token secret for the AccessToken instance.
#access_token = prepare_access_token( config.access_token, config.access_secret, config.consumer_token, config.consumer_secret )
# puts results_user.inspect

config.set :name, results_user['name']
config.set :total_tweets, [ results_user["statuses_count"], config.tweets_hard_limit ].min
config.set :times_to_loop, (config.total_tweets * 1.0 / config.tweets_per_call).ceil


# abort
# response = access_token.request(:get, "http://api.twitter.com/1/users/show.json?screen_name=" + screen_name )
#results_user = JSON::parse(response.body)


config.times_to_loop.times { |pg|
	#response = access_token.request(:get, "https://api.twitter.com/1/statuses/user_timeline.json?include_entities=0&include_rts=0&screen_name="+screen_name+"&count="+tweets_per_call.to_s+"&trim_user=t&page="+(pg+1).to_s)
	#if !response.is_a?(Net::HTTPOK)
	#	puts "Redoing page #{pg+1}" 
	#	redo
	#end
	#results = JSON::parse(response.body)
	results = connect.get do |c|
		c.use_oauth true
		c.url "https://api.twitter.com/1/statuses/user_timeline.json?include_entities=0&include_rts=0&screen_name=#{screen_name}&count=#{config.tweets_per_call}&trim_user=t&page=#{(pg+1)}" , "Redoing page #{pg+1}"
		c.get_json
	end
	results.each { |twt| 
		dt = DateTime.parse( twt['created_at'] )
		dty = dt.strftime("%Y")
		dtm = dt.strftime("%m")
		tweet_section[dty] ||= {}
		tweet_section[dty][dtm] ||= []
		
		
		
		tweet_section[dty][dtm] << TweetRetriever.grab do |tweet|
			name name
			screen_name screen_name
			id twt['id']
			text twt['text']
			created_at twt['created_at']
			in_reply_to_screen_name twt['in_reply_to_screen_name']
			in_reply_to_status_id twt["in_reply_to_status_id"]  
		end
	}
}
TweetRetriever.write_to_disk( tweet_section )
