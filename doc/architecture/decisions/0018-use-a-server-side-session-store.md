# 17. use-a-server-side-session-store

Date: 2020-03-17

## Status

Accepted

## Context

We have a CookieOverflow error that is prompting this work [4]. It occurs when the service is storing more than 4KB of data within the cookie. This includes information on the user, auth tokens and the content of any flash messages.

A current work-around is to delete your cookie and sign in again.

Rails acknowledges [5] that the default cookie storage is fast but prone to this error.

## Decision

Use ActiveRecord session store gem [1] as a server-side session store.

## Consequences

This gem is maintained by Rails and is likely to be compatible with new versions of Rails.

The gem requires a secondary scheduled task to be run in order to clean up old and expired sessions from the database. Without this, the database will fill up with many thousands of records and this problem could bite the service later due to database limits. Scheduled tasks are not formally supported by GPaaS at the moment [2] however we should be able to work around this by using the sidekiq-cron gem [3] as we already have Sidekiq in place.

[1] https://github.com/rails/activerecord-session_store
[2] https://github.com/alphagov/paas-roadmap/issues/52
[3] https://github.com/ondrejbartas/sidekiq-cron
[4] https://api.rubyonrails.org/classes/ActionDispatch/Session/CookieStore.html
[5] https://guides.rubyonrails.org/security.html#session-storage
