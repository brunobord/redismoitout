require 'rubygems'
require 'redis'
require 'sinatra'
require 'erb'

$messages = []

# Helpers
class String
    # checks if a string is composed of digits
    def is_numeric?
        !!Float(self) rescue false
    end
end

# Shortcut to assign a value to the key
def set_key(key, value)
    $redis.set key, value
    redirect "/k/#{key}/"
end

# Shortcut to increment a value to the key
def incr_key(key)
    $redis.incr key
    redirect "/k/#{key}/"
end

# -----

# Flash Message. Should be displayed only once and vanish from the session
class FlashMessage
    attr_accessor :message, :level
    def initialize(message, level='success')
        raise ArgumentError, "Argument must be in ['success', 'error', 'info', 'block']" unless ['success', 'error', 'info', 'block'].include? level
        @message = message
        @level = level
    end
end

# -----

# Will be executed before every request
before do
    pass if request.path_info == "/login/"
    if not $redis.nil?
        begin
            $redis.ping
        rescue Redis::CannotConnectError
            $messages.clear
            $messages.push(FlashMessage.new 'Connection failed. The target server is probably not accessible', 'error')
            redirect '/login/'
        rescue Redis::CommandError
            $messages.clear # no way to keep on
            $messages.push(FlashMessage.new 'Connection failed, please retry and make sure you are providing the correct parameters', 'error')
            redirect '/login/'
        end
    else
        redirect '/login/'
    end
end

# Home page.
get '/' do
    @search = "*" # Default value
    if not params[:search].nil? and params[:search] != ""
        @search = params[:search]
    end
    @keys = $redis.keys(@search)
    erb :index
end

# Access to the login form
get '/login/' do
    erb :login
end

# Process the login form - Handles authentication
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

# Log out.
get '/logout/' do
    $redis = nil
    redirect '/'
end

# Display key details (value, meta-information)
get '/k/:key/' do |key|
    @key = key
    @type = $redis.type key

    case @type
    when "string"
        @value = $redis.get key
        @numeric = @value.is_numeric?
    when "list"
        @value = $redis.lrange key, 0, -1
    else
        @value = nil
        $messages.push(FlashMessage.new 'Unknown/Unimplemented type', "error")
    end
    # checks on values
    @ttl = $redis.ttl key
    erb :detail
end

# Process 'SET' form
post '/set/' do
    set_key params[:key], params[:value]
end

# Process the "DEL" button
get '/del/:key/' do |key|
    $redis.del params[:key]
    $messages.push(FlashMessage.new "`#{params[:key]}` deleted", "error")
    redirect '/'
end

# INCR button
get '/incr/:key/' do
    incr_key params[:key]
end

# INCR form (modal popup) processing
post '/incr/' do
    incr_key params[:key]
end

# RPUSH form processing
post '/rpush/' do
    $redis.rpush params[:key], params[:value]
    redirect "/k/#{params[:key]}/"
end

# LPUSH form processing
post '/lpush/' do
    $redis.lpush params[:key], params[:value]
    redirect "/k/#{params[:key]}/"
end

# EXPIRE form (modal popup) processing
post '/expire/' do
    $redis.expire params[:key], params[:ttl]
    redirect "/k/#{params[:key]}/"
end

# INFO page (server general information)
get '/info/' do
    @info = $redis.info
    erb :info
end

# Modals
$modals = {
    'ttl' => {
        'modal_id' => 'change-ttl',
        'modal_action' => '/expire/',
        'modal_title' => 'Change TTL',
        'modal_form' => '<label for="ttl">Here you can change the TTL value</label>
            <input type="text" name="ttl">
            <input type="hidden" name="key" value="<%= key%>">'
    },
    'set-new' => {
        'modal_id' => 'set-new',
        'modal_action' => '/set/',
        'modal_title' => 'Set a new value',
        'modal_form' => '<label for="key">Key name</label>
            <input type="text" name="key">
            <label for="value">Value</label>
            <input type="text" name="value">'
    },
    'set' => {
        'modal_id' => 'set',
        'modal_action' => '/set/',
        'modal_title' => 'Change value',
        'modal_form' => '<label for="value">Assign a value</label>
            <input type="text" name="value" value="<%= value%>">
            <input type="hidden" name="key" value="<%= key%>">'
    }
}

get '/modal/:modal/' do |modal|
    if not $modals.key? modal
        status 404
    end
    modal = $modals[modal]
    if not modal.nil?
        @modal_id = modal['modal_id']
        @modal_action = modal['modal_action']
        @modal_title = modal['modal_title']
        modal_form_template = ERB.new modal['modal_form']
        key = params["key"]
        value = params["value"]
        @modal_form = modal_form_template.result(binding)
        erb :modal, :layout => false
    end
end
