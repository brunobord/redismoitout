require 'rubygems'
require 'redis'
require 'sinatra'

$messages = []

# Helpers
class String
    def is_numeric?
        !!Float(self) rescue false
    end
end

class FlashMessage
    attr_accessor :message, :level
    def initialize(message, level='success')
        raise ArgumentError, "Argument must be in ['success', 'error', 'info', 'block']" unless ['success', 'error', 'info', 'block'].include? level
        @message = message
        @level = level
    end
end

def set_key(key, value)
    $redis.set key, value
    redirect "/k/#{key}/"
end

def incr_key(key)
    $redis.incr key
    redirect "/k/#{key}/"
end

before do
    pass if request.path_info == "/login/"
    if not $redis.nil?
        begin
            $redis.ping
        rescue Redis::CommandError
            $messages.clear # no way to keep on
            $messages.push(FlashMessage.new 'Connection failed, please retry and make sure you are providing the correct parameters', 'error')
            redirect '/login/'
        end
    else
        redirect '/login/'
    end
end

get '/' do
    @search = "*" # Default value
    if not params[:search].nil? and params[:search] != ""
        @search = params[:search]
    end
    @keys = $redis.keys(@search)
    erb :index
end

get '/login/' do
    erb :login
end

post '/login/' do
    $redis = Redis.new :host=>params[:host], :port=>params[:port]
    if params[:password] != ''
        begin
            $redis.auth params[:password]
        rescue Redis::CommandError
            $messages.push(FlashMessage.new "Wrong password", "error")
            redirect '/login/'
        end
    end
    $messages.push(FlashMessage.new 'You are logged in')
    redirect '/'
end

get '/logout/' do
    $redis = nil
    logger.info $messages
    redirect '/'
end

get '/k/:key/' do |key|
    @key = key
    begin
        @value = $redis.get key
        @type = "string"
        @numeric = @value.is_numeric?
    rescue Redis::CommandError
        @value = $redis.lrange key, 0, -1
        @type = 'list'
    end
    # checks on values
    @ttl = $redis.ttl key
    erb :detail
end

post '/set/' do
    logger.info "Set numero #1"
    set_key params[:key], params[:value]
end

get '/del/:key/' do |key|
    $redis.del params[:key]
    $messages.push(FlashMessage.new "`#{params[:key]}` deleted", "error")
    redirect '/'
end

get '/incr/:key/' do
    incr_key params[:key]
end

post '/incr/' do
    incr_key params[:key]
end

post '/rpush/' do
    $redis.rpush params[:key], params[:value]
    redirect "/k/#{params[:key]}/"
end

post '/lpush/' do
    $redis.lpush params[:key], params[:value]
    redirect "/k/#{params[:key]}/"
end

post '/expire/' do
    $redis.expire params[:key], params[:ttl]
    redirect "/k/#{params[:key]}/"
end

get '/info/' do
    @info = $redis.info
    erb :info
end
