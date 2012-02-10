module TweetRetriever
	class Config
		#attr_accessor :config
		def initialize( filename )
			config = JSON::parse(File.read( filename )) rescue abort("Cannot Parse JSON Config file: config.json")
			config.each {|key, value|
				instance_variable_set("@" + key, value)
				self.class.send :define_method, key.to_sym do
					instance_variable_get("@" + key)
				end
			}
			json_checks
			create_json_dir
		end
		
		# Make Config checks
		def json_checks
			config = {}
			abort "Consumer and Access Token information is not set" if ( 
				access_token.empty? ||
				access_secret.empty? ||
				consumer_token.empty? ||
				consumer_secret.empty?
			)
			abort "No screenname specified" if (screen_name.empty?)
		end
		
		def create_json_dir
			Dir.mkdir("./json") if Dir["./json"].length == 0 rescue abort("Cannot create directory to store JSON")
		end
		# pulls basic info about user we want to grab
		def use_oauth
			
		end
		
		def use_http
		end
	end
	
	def TweetRetriever.grab( &blk )
		tweet = TweetRetriever::Tweet.new( &blk ).to_h
	end
	
	def TweetRetriever.write_to_disk( tweets )
		tweets.each { |month, day_keys|
			day_keys.each { |day, tweet|
				File.open("./json/" + month + "_" + day + ".json",'w') {|f| f.write( JSON.pretty_generate(tweet) ) }
			}
		}
	end
	
	class Tweet
		attr_reader :hash_form
		def to_h 
			return @hash_form
		end
		def initialize( &blk ) 
			@hash_form = {}
			instance_eval( &blk )
		end	
		def method_missing(m, *args)
			@hash_form[m] = args[0]
		end
	end
	
	
	
end