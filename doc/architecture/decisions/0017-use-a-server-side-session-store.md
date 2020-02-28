# 17. use-a-server-side-session-store

Date: 2020-02-28

## Status

Accepted

## Context

We are proactively checking that we are securing the service before it goes live to real users. Using past experience and penetration feedback the subject of where we store our sessions has previously been approved that we store the data server side, rather than leaving reusable tokens in people's browsers and trusting in the cookie's encryption.

https://api.rubyonrails.org/classes/ActionDispatch/Session/CookieStore.html
https://guides.rubyonrails.org/security.html#session-storage

dxw have used both active record and redis stores in the past using the following gems:

- https://github.com/rails/activerecord-session_store
- https://github.com/redis-store/redis-store/
- https://github.com/roidrage/redis-session-store


## Decision

Use Redis as a server-side session store using https://github.com/redis-store/redis-store/.

## Consequences

User sessions will now be stored in a private Redis database without encryption.

Using Redis over ActiveRecord has a couple of small advantages:
 - Redis does not require a rake task that is scheduled by a separate process like cron to remove old sessions, it is instead a configuration option for Redis 
 - Sessions would not contribute to the usage of postgres database which is expecting to be heavily used
 - Destroying all sessions in the case of an incident is a much safer option using redis-cli than it would be to hop onto a production rails console and manually delete rows from only a single table, this would be a much more dangerous operation if important data was available from within the same context 

There may be some advantages of using the Rails maintained activerecord-session_store that we miss out on as Rails changes. Since it is maintained by the Rails core team this is a likely benefit.

The redis gem we are using is maintained by the core Redis team, is actively maintained too and offers us an easy path into performing any caching at an application level in the future.
