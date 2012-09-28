# Redis-Moi Tout

This is a Sinatra-based web interface to manage redis databases.

![Screenshot](http://farm9.staticflickr.com/8435/7742349534_6876bc87ed_c.jpg)


## Usage

Once Sinatra and redis gems are installed, just run:

    ruby redismoitout.rb

and point your browser to [http://localhost:4567/](http://localhost:4567/)

You'll have to logon to your Redis server by providing its *host* and *port*.

## Implemented methods

* AUTH
* KEYS
* INFO
* GET
* SET
* DEL
* INCR
* TTL
* EXPIRE
* LRANGE
* LPUSH (partial, only works on existing keys)
* RPUSH (partial, only works on existing keys)
* SADD (create and update sets)

As you can see... it's still a very young project.

### Notes on search

In the search form you can specify a key pattern using "*" as a joker character.
For more information, please refer to the [KEYS command official documentation](http://redis.io/commands/keys)

----

## License

This piece of software is distributed "AS IS", and since it's "only" an exercise
to play around with Ruby, Sinatra and Redis, it is licensed under the terms of
the WTFPL.

See [http://sam.zoy.org/wtfpl/COPYING](http://sam.zoy.org/wtfpl/COPYING) for the
full text of this license.
