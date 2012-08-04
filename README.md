# Redis-Moi-Ça

This is a Sinatra-based web interface to manage redis databases.

## Usage

Once Sinatra and redis gems are installed, just run:

    ruby redismoica.rb

and point your browser to [http://localhost:4567/](http://localhost:4567/)

You'll have to logon to your Redis server by providing its *host* and *port*.

## Implemented methods

* KEYS
* INFO
* GET
* SET
* DEL
* INCR
* TTL
* EXPIRE
* LRANGE

As you can see... it's still a very young project.

----

## License

This piece of software is distributed "AS IS", and since it's "only" an exercise
to play around with Ruby, Sinatra and Redis, it is licensed under the terms of
the WTFPL.

See [http://sam.zoy.org/wtfpl/COPYING](http://sam.zoy.org/wtfpl/COPYING) for the
full text of this license.
