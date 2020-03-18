# 17. use-a-server-side-session-store

Date: 2020-03-17

## Status

Accepted

## Context

We have a CookieOverflow error that is prompting this work [4]. It occurs when the service is storing more than 4KB of data within the cookie. This includes information on the user, auth tokens and the content of any flash messages.

A current work-around is to delete your cookie and sign in again.

Rails acknowledges [5] that the default cookie storage is fast but prone to this error.

## Decision

Use Redis [1] as a server-side session store.

## Consequences

This gem is maintained by Redis and is a popular choice for session management.

The service is already using Redis so additional set up is not required.

Scheduled tasks are not formally supported by GPaaS at the moment [2] i order to clean up sessions with rake tasks however Redis has a time to live option which will clean this up without additional effort.

Redis will encrypt the session data at rest and serve the session back to the users browser for them to decrypt. Not having it unencrypted at rest would provide more defence in depth as Redis is already protected from public access at a network level.

[1] https://github.com/redis-store/redis-rails#session-storage
[2] https://github.com/alphagov/paas-roadmap/issues/52
[4] https://api.rubyonrails.org/classes/ActionDispatch/Session/CookieStore.html
[5] https://guides.rubyonrails.org/security.html#session-storage
