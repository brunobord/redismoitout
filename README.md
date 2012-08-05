# Redis-Moi-Ça

This is a Sinatra-based web interface to manage redis databases.

## Usage

Once Sinatra and redis gems are installed, just run:

    ruby redismoica.rb

and point your browser to [http://localhost:4567/](http://localhost:4567/)

You'll have to logon to your Redis server by providing its *host* and *port*.

## Implemented methods

* KEYS (partial, no query support)
* INFO
* GET
* SET (partial, only works on existing keys)
* DEL
* INCR (partial, only works on existing keys)
* TTL
* EXPIRE
* LRANGE
* LPUSH (partial, only works on existing keys)
* RPUSH (partial, only works on existing keys)

As you can see... it's still a very young project.

**WARNING**: this program cannot create keys yet. It only works on existing keys.

----

## License

This piece of software is distributed "AS IS", and since it's "only" an exercise
to play around with Ruby, Sinatra and Redis, it is licensed under the terms of
the WTFPL.

See [http://sam.zoy.org/wtfpl/COPYING](http://sam.zoy.org/wtfpl/COPYING) for the
full text of this license.
