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

get '/k/:key/' do
    @key = params[:key]
    @value = $redis.get params[:key]
    # checks on values
    @numeric = @value.is_numeric?
    erb :value
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

get '/info/' do
    @info = $redis.info
    erb :info
end

__END__

@@layout
<!DOCTYPE html>
<html lang="en">
    <head>
        <title><%= @title %></title>
        <link rel="stylesheet" type="text/css" href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.0.4/css/bootstrap-combined.min.css"/>
        <script type="text/javascript" src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.0.4/js/bootstrap.min.js"></script>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body>
        <div class="navbar">
            <div class="navbar-inner">
                <div class="container">
                    <ul class="nav">
                        <li><a href="/">Home</a></li>
                    </ul>
                    <ul class="nav pull-right">
                        <% if not $redis.nil? %>
                            <li><a href="/info/">Server Info</a></li>
                            <li><a href="/logout/">Logout</a></li>
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
<div class="row">
    <div class="offset2 span8">
        <div class="well">
        <p>Key: <%= @key%></p>
        <p>Value: <%= @value%></p>
        </div>
        <p>
            <a href="/del/<%= @key%>/" class="btn btn-danger">delete</a>
            <% if @numeric %><a href="/incr/<%= @key%>/" class="btn btn-info">Incr</a><% end %>
        </p>

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