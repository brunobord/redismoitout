require 'rubygems'
require 'redis'
require 'sinatra'

# $redis = nil

get '/' do
    if $redis.nil?
        redirect '/login'
    end
    @keys = $redis.keys('*')
    logger.info @keys
    erb :index
end

get '/k/:key' do
    @key = params[:key]
    @value = $redis.get params[:key]
    erb :value
end


get '/login' do
    erb :login
end

post '/login' do
    $redis = Redis.new :host=>params[:host], :port=>params[:port]
    redirect '/'
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
        <div class="container">
        <h1>Redis-Moi-Ça</h1
        <%= yield%>
        </div>
    </body>
</html>

@@index

<div class="row">
  <div class="span6">
    <h2>Connected</h2>
    <table class="table table-striped">
        <thead>
            <tr>
                <th>#</th>
                <th>Keys</th>
            </tr>
        </thead>
        <tbody>
        <% @keys.each_with_index do |key, idx| %>
            <tr>
                <td><%= idx%></td>
                <td><a href="/k/<%= key%>"><%= key%></a></td>
            </tr>
        <% end %>
        </tbody>
    </table>
  </div>
</div>


@@login
<p>Please login</p>
<form method="post" action="/login" class="well form-inline">
    <label for="host">Host</label><input name="host" type="text" value="127.0.0.1">
    <label for="port">Port</label><input name="port" type="text" value="6379">
    <input type="submit">
</form>

@@value
<p>Key: <%= @key%></p>
<p>Value: <%= @value%></p>
