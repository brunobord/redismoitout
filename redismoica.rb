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
        @message = message
        @level = level
    end
end

before do
    pass if request.path_info == "/login/"
    if $redis.nil?
        redirect '/login/'
    end
end

get '/' do
    @keys = $redis.keys('*')
    erb :index
end

get '/login/' do
    erb :login
end

post '/login/' do
    $redis = Redis.new :host=>params[:host], :port=>params[:port]
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
    erb :value
end

post '/set/:key/' do |key|
    $redis.set key, params[:value]
    redirect "/k/#{key}/"
end

get '/del/:key/' do |key|
    $redis.del key
    $messages.push(FlashMessage.new "`#{key}` deleted", "error")
    redirect '/'
end

get '/incr/:key/' do |key|
    $redis.incr key
    redirect "/k/#{key}/"
end

post '/expire/:key/' do |key|
    $redis.expire key, params[:ttl]
    redirect "/k/#{key}/"
end

get '/info/' do
    @info = $redis.info
    erb :info
end

__END__

@@layout
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Redis-Moi-Ça</title>
        <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
        <script type="text/javascript" src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.0.4/js/bootstrap.min.js"></script>
        <link rel="stylesheet" type="text/css" href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.0.4/css/bootstrap-combined.min.css"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body>
        <div class="navbar">
            <div class="navbar-inner">
                <div class="container">
                    <ul class="nav">
                        <li><a href="/"><i class="icon-home icon-white"></i> Home</a></li>
                    </ul>
                    <ul class="nav pull-right">
                        <% if not $redis.nil? %>
                            <li><a href="/info/"><i class="icon-info-sign icon-white"></i> Server Info</a></li>
                            <li><a href="/logout/"><i class="icon-off icon-white"></i> Logout</a></li>
                        <% end %>
                    </ul>
                </div>
            </div>
        </div>
        <div class="container">
            <div class="page-header">
            <h1 class="brand">Redis-Moi-Ça</h1>
            </div>
                <%
                if not $messages.nil?
                    if $messages.size > 0
                        for message in $messages %>
                        <div class="alert alert-<%=message.level%>">
                        <%= message.message%>
                        </div><%
                        end
                    end
                end
                # must do the logic here, it seems.
                $messages = [] # whatever
                %>
            <%= yield%>
        </div>
    </body>
</html>


@@index
<div class="row">
  <div class="offset2 span8">
    <h2>Connected</h2>
    <table class="table table-striped">
        <thead>
            <tr>
                <th>#</th>
                <th>Keys</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
        <% @keys.each_with_index do |key, idx| %>
            <tr>
                <td><%= idx%></td>
                <td><a href="/k/<%= key%>/"><%= key%></a></td>
                <td><a href="/del/<%= key%>/" class="btn btn-danger btn-small">del</a></td>
            </tr>
        <% end %>
        </tbody>
    </table>
  </div>
</div>


@@login
<div class="row">
  <div class="offset2 span8">
    <h2>Please login</h2>
    <form method="post" action="/login/" class="well">
        <label for="host">Host</label> <input name="host" type="text" value="127.0.0.1">
        <label for="port">Port</label> <input name="port" type="text" value="6379">
        <p><button type="submit" class="btn btn-primary">Connect</button></p>
    </form>
    </div>
</div>


@@value
<div class="modal hide" id="change-ttl">
  <form method="post" action="/expire/<%= @key%>/">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Change TTL</h3>
  </div>
  <div class="modal-body">
    <label for="ttl">Here you can change the TTL value</label>
    <input type="text" name="ttl">
  </div>
  <div class="modal-footer">
    <a href="#" class="btn" data-dismiss="modal">Cancel</a>
    <button type="submit" class="btn btn-primary">Save changes</button>
  </div>
  </form>
</div>

<div class="modal hide" id="set">
  <form method="post" action="/set/<%= @key%>/">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Set value</h3>
  </div>
  <div class="modal-body">
    <label for="ttl">Assign a value</label>
    <input type="text" name="value" value="<%= @value%>">
  </div>
  <div class="modal-footer">
    <a href="#" class="btn" data-dismiss="modal">Cancel</a>
    <button type="submit" class="btn btn-primary">Save changes</button>
  </div>
  </form>
</div>

<div class="row">
    <div class="offset2 span6 well">
        <h3>Main data</h3>
        <dl>
            <dt>Key</dt><dd><%= @key%></dd>
            <dt>Value</dt><dd>
                <% if @type == 'string' %>
                    <%= @value%>
                <% elsif @type == 'list' %>
                    [<%= @value.join ', ' %>]
                <% end %>
            </dd>
        </dl>
        <p>
            <a href="/del/<%= @key%>/" class="btn btn-danger">Delete</a>
            <% if @numeric %><a href="/incr/<%= @key%>/" class="btn btn-info">Increment</a><% end %>
            <% if @type == 'string' %><a class="btn btn-primary" data-toggle="modal" data-target="#set">Set</a><% end %>
        </p>
    </div>
    <div class="span3 well">
        <h3>Other data</h3>
        <dl>
            <dt><abbr class="initialism" title="Time To Live">TTL</abbr></dt>
            <dd><%= @ttl%>
                <a class="btn btn-small" data-toggle="modal" data-target="#change-ttl">Change TTL</a>
            </dd>
        </dl>
    </div>
</div>


@@info
<div class="row">
    <div class="offset2 span8">
    <h2>Server info</h2>
    <table class="table table-striped">
        <thead>
            <tr>
                <th>#</th>
                <th>Keys</th>
                <th>Values</th>
            </tr>
        </thead>
        <tbody>
        <% @info.each_with_index do |(key, value), idx| %>
            <tr>
                <td><%= idx%></td>
                <td><%= key%></td>
                <td><%= value%></td>
            </tr>
        <% end %>
        </tbody>
    </table>
    </div>
</div>