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
		def set( name, value )
			instance_variable_set("@" + name.to_s, value)
			self.class.send :define_method, name.to_sym do
				instance_variable_get("@" + name.to_s)
			end
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
	
	class Connect 
		attr_accessor :use_oauth, :config, :response, :access_token
		def initialize(config)
			@config = config
			@use_oauth = false
			# Exchange our oauth_token and oauth_token secret for the AccessToken instance.
			#
			@@access_token ||= prepare_access_token( config.access_token, config.access_secret, config.consumer_token, config.consumer_secret )
		end
		
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
		def use_oauth( bool_value )
			@use_oauth = true
		end
		def url( url, redo_msg ="" ) 
			begin 
				@response = @@access_token.request(:get, url )
				puts redo_msg unless redo_msg.empty? || @response.is_a?(Net::HTTPOK) 
			end until @response.is_a?(Net::HTTPOK)
		end	
		def get_json
			JSON::parse(@response.body)
		end
		def get( &block )
			instance_eval(&block) if block_given?
		end

		
	end
	
	
	
end
