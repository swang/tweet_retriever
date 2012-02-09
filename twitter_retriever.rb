require "oauth"
require "json"
# require "ap"
require "time"

config = JSON::parse(File.read("./config.json")) rescue abort("Cannot Parse JSON Config file: config.json")

def prepare_access_token(oauth_token, oauth_token_secret, consumer_token, consumer_secret)
  	consumer = OAuth::Consumer.new(	consumer_token, 
  									consumer_secret, 
  									{ :site => "http://api.twitter.com", :scheme => :header})
	# now create the access token object from passed values
  	token_hash = { 	:oauth_token => oauth_token,
                	:oauth_token_secret => oauth_token_secret
	}
  	access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
end

# Make Config checks
abort "Consumer and Access Token information is not set" if ( config['access_token'].empty? ||
														 	 config['access_secret'].empty? ||
														 	 config['consumer_token'].empty? ||
														 	 config['consumer_secret'].empty? )

abort "No screenname specified" if (config['screen_name'].empty?)

Dir.mkdir("./json") if Dir["./json"].length == 0 rescue abort("Cannot create directory to store JSON")

# Initialize some variables
tweet_section = {}
times_to_loop = 0
tweets_per_call = config['tweets_per_call']
screen_name = config['screen_name']

# Exchange our oauth_token and oauth_token secret for the AccessToken instance.
access_token = prepare_access_token( config['access_token'], config['access_secret'], config['consumer_token'], config['consumer_secret'] )

response = access_token.request(:get, "http://api.twitter.com/1/users/show.json?screen_name=" + screen_name )
results_user = JSON::parse(response.body)
name = results_user['name']
total_tweets = [ results_user["statuses_count"], config["tweets_hard_limit"]].min
times_to_loop = (total_tweets * 1.0 / tweets_per_call).ceil

times_to_loop.times { |pg|
	response = access_token.request(:get, "https://api.twitter.com/1/statuses/user_timeline.json?include_entities=0&include_rts=0&screen_name="+screen_name+"&count="+tweets_per_call.to_s+"&trim_user=t&page="+(pg+1).to_s)
	if !response.is_a?(Net::HTTPOK)
		puts "Redoing page #{pg+1}" 
		redo
	end
	results = JSON::parse(response.body)
	results.each { |twt| 
		dt = DateTime.parse( twt['created_at'] )
		dty = dt.strftime("%Y")
		dtm = dt.strftime("%m")
		tweet_section[dty] = {} if tweet_section[dty].nil?
		tweet_section[dty][dtm] = [] if tweet_section[dty][dtm].nil?
		tweet_section[dty][dtm] << {
			"name" => name,
			"screen_name" => screen_name,
			"id" => twt['id'],
			"text" => twt['text'],
			"created_at" => twt['created_at'],
			"in_reply_to_screen_name" => twt['in_reply_to_screen_name'],
			"in_reply_to_status_id" => twt["in_reply_to_status_id"]  
		}
	}
}
tweet_section.each { |month, day_keys|
	day_keys.each { |day, tweet|
		File.open("./json/" + month + "_" + day + ".json",'w') {|f| f.write( JSON.pretty_generate(tweet) ) }
	}
}