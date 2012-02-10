
$: << "."
require "oauth"
require "json"
# require "ap"
require "time"

require "lib/tweet_retriever"


# Initialize some variables
tweet_section = {}
config = TweetRetriever::Config.new("config.json")
screen_name = config.screen_name

connect = TweetRetriever::Connect.new(config)

results_user = connect.get do |c|
	c.use_oauth true
	c.url "http://api.twitter.com/1/users/show.json?screen_name=" + screen_name
	c.get_json
end

config.set :name, results_user['name']
config.set :total_tweets, [ results_user["statuses_count"], config.tweets_hard_limit ].min
config.set :times_to_loop, (config.total_tweets * 1.0 / config.tweets_per_call).ceil

config.times_to_loop.times { |pg|
	
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
