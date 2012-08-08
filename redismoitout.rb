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

post '/set/' do
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

__END__

@@layout
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Redis-Moi Tout</title>
        <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
        <script type="text/javascript" src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.0.4/js/bootstrap.min.js"></script>
        <link rel="stylesheet" type="text/css" href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.0.4/css/bootstrap-combined.min.css" />
        <link href="data:image/x-icon;base64,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" rel="icon" type="image/x-icon" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <style type="text/css">
            .footer {
                margin-top: 45px;
                padding: 35px 0 36px;
                border-top: 1px solid #E5E5E5;
            }
            .subnav {
                padding-bottom: 1em;
            }
        </style>
    </head>
    <body>
        <div class="container">

            <div class="navbar">
                <div class="navbar-inner">
                    <div class="container">
                        <ul class="nav">
                            <li><a href="/"><i class="icon-home icon-white"></i> Home</a></li>
                        </ul>
                        <% if not $redis.nil? %>
                        <ul class="nav pull-right">
                            <li><a href="/info/"><i class="icon-info-sign icon-white"></i> Server Info</a></li>
                            <li><a href="/logout/"><i class="icon-off icon-white"></i> Logout</a></li>
                        </ul>
                        <form class="navbar-search pull-right" action="/">
                        <input type="text" class="search-query" placeholder="Search" name="search" value="<%= @search if not @search.nil? and @search != "*" %>">
                        </form>
                        <% end %>
                    </div>
                </div>
            </div>

            <div class="page-header">
            <h1 class="brand">Redis-Moi Tout</h1>
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

            <% if not $redis.nil? %>
            <section class="subnav">
            <div class="row">
                <div class="offset2 span8">
                    <div class="pull-right btn-group">
                        <a class="btn btn-small" data-toggle="modal" data-target="#set-new">SET new</a>
                        <a class="btn btn-small" data-toggle="modal" data-target="#incr-new">INCR new</a>
                    </div>
                </div>
            </div>
            </section>
            <% end %>

            <%= yield%>

            <footer class="footer">
                <p>Made using <a href="http://git-scm.com/">Git</a>, <a href="http://www.sublimetext.com/">SublimeText 2</a>,
                <a href="http://www.sinatrarb.com/">Sinatra</a>, and <a href="http://twitter.github.com/bootstrap/">Twitter Bootstrap</a>.</p>
                <p>Built by <a href="http://jehaisleprintemps.net/">Bruno Bord </a> - 2012. You can <a href="http://github.com/brunobord/redismoitout">fork it</a>, it's open.</p>
            </footer>

        </div>

    <!-- Dialogs -->
<div class="modal hide" id="set-new">
  <form method="post" action="/set/">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Set a new value</h3>
  </div>
  <div class="modal-body">
    <label for="key">Key name</label>
    <input type="text" name="key">
    <label for="key">Value</label>
    <input type="text" name="value">
  </div>
  <div class="modal-footer">
    <a href="#" class="btn" data-dismiss="modal">Cancel</a>
    <button type="submit" class="btn btn-primary">Save changes</button>
  </div>
  </form>
</div>

<div class="modal hide" id="incr-new">
  <form method="post" action="/incr/">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Create a new counter</h3>
  </div>
  <div class="modal-body">
    <label for="key">Key name</label>
    <input type="text" name="key">
  </div>
  <div class="modal-footer">
    <a href="#" class="btn" data-dismiss="modal">Cancel</a>
    <button type="submit" class="btn btn-primary">Save changes</button>
  </div>
  </form>
</div>

    </body>
</html>


@@index
<div class="row">
  <div class="offset2 span8">
    <h2>Key List</h2>
    <% if @search != "*" %>
    <p>Searched keys: <em><%= @search%></em></p>
    <% end %>
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
        <label for="Password">Password</label> <input name="password" type="password" value="" placeholder="Password">
        <span class="help-block">Optional authentication. May be required by your server.</span>
        <p><button type="submit" class="btn btn-primary">Connect</button></p>
    </form>
    </div>
</div>


@@value
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
            <% if @type == 'list' %>
                <dt>Length</dt>
                <dd><%= @value.length%></dd>
            <% end %>
        </dl>
        <p>
            <% if @numeric %><a href="/incr/<%= @key%>/" class="btn btn-info">Increment</a><% end %>
            <% if @type == 'string' %><a class="btn btn-info" data-toggle="modal" data-target="#set">Set</a><% end %>
            <% if @type == 'list' %>
                <a class="btn btn-info" data-toggle="modal" data-target="#lpush">LPush</a>
                <a class="btn btn-info" data-toggle="modal" data-target="#rpush">RPush</a>
            <% end %>
            <a href="/del/<%= @key%>/" class="btn btn-danger">Delete</a>
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

<!-- Dialogs -->
<div class="modal hide" id="change-ttl">
  <form method="post" action="/expire/">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Change TTL</h3>
  </div>
  <div class="modal-body">
    <label for="ttl">Here you can change the TTL value</label>
    <input type="text" name="ttl">
    <input type="hidden" name="key" value="<%= @key%>">
  </div>
  <div class="modal-footer">
    <a href="#" class="btn" data-dismiss="modal">Cancel</a>
    <button type="submit" class="btn btn-primary">Save changes</button>
  </div>
  </form>
</div>

<div class="modal hide" id="set">
  <form method="post" action="/set/">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Set value</h3>
  </div>
  <div class="modal-body">
    <label for="value">Assign a value</label>
    <input type="text" name="value" value="<%= @value%>">
    <input type="hidden" name="key" value="<%= @key%>">
  </div>
  <div class="modal-footer">
    <a href="#" class="btn" data-dismiss="modal">Cancel</a>
    <button type="submit" class="btn btn-primary">Save changes</button>
  </div>
  </form>
</div>

<div class="modal hide" id="lpush">
  <form method="post" action="/lpush/">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Left push</h3>
  </div>
  <div class="modal-body">
    <label for="value">Push a value on the left</label>
    <input type="text" name="value">
    <input type="hidden" name="key" value="<%= @key%>">
  </div>
  <div class="modal-footer">
    <a href="#" class="btn" data-dismiss="modal">Cancel</a>
    <button type="submit" class="btn btn-primary">Save changes</button>
  </div>
  </form>
</div>

<div class="modal hide" id="rpush">
  <form method="post" action="/rpush/">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Right push</h3>
  </div>
  <div class="modal-body">
    <label for="value">Push a value on the right</label>
    <input type="text" name="value">
    <input type="hidden" name="key" value="<%= @key%>">
  </div>
  <div class="modal-footer">
    <a href="#" class="btn" data-dismiss="modal">Cancel</a>
    <button type="submit" class="btn btn-primary">Save changes</button>
  </div>
  </form>
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
