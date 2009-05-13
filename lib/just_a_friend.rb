require 'optparse'
require 'typhoeus'
require 'json'

class Twitter
  include Typhoeus
  
  remote_defaults :on_success => lambda { |resp| JSON.load(resp.body) },
                  :on_failure => lambda { |resp| puts "error: #{resp.code}" },
                  :base_uri => 'http://twitter.com'
                  
  define_remote_method :friends, :path => '/statuses/friends.json'
  
  def self.all_friends(screen_name)
    page = 0
    response = friends(:params => {:screen_name => screen_name, :page => page})
    while response.length != 0
      all_friends << response
      page = page.succ
      response = friends(:params => {:screen_name => screen_name, :page => page})
    end
    all_friends.flatten
  end
end

class Delicious
  include Typhoeus
  
  remote_defaults :on_success => lambda { |resp| true },
                  :on_failure => lambda { |resp| false if resp.code == 404 },
                  :base_uri => 'http://delicious.com'
  
  define_remote_method :user_bookmarks, :path => '/:username'
end

class JustAFriend
  
  def self.main
    
    op = OptionParser.new do |opts|
      opts.banner = 'Usage: just_a_friend [options] <username>'
      opts.separator 'Options:'
      opts.on('-h', '--help', 'Display this message') do |h|
        STDOUT.puts opts
        exit
      end
    end
    
    op.parse!(ARGV)
    
    if ARGV.length != 1
      puts "Missing required screen name parameter."
      exit
    end
    
    username = ARGV[0]
    friends = Twitter.friends(:params => {:screen_name => username})
    friends.map { |f| puts "#{f['name']} - #{f['screen_name']} - #{Delicious.user_bookmarks(:username => f['screen_name'])}" }
  end
  
end