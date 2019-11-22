# 9. use-sidekiq-and-redis-to-send-emails

Date: 2019-11-22

## Status

Accepted

## Context

The service needs to send invitation emails through Notify. The service will likely need to send more notifications in future to send reminders or notify of approvals etc.

We could use a Postgres backed queue using DelayedJob instead of Redis to remove a dependency.

Sidekiq and Redis are a well used and trusted combo for dxw delivery teams and are familiar in the community.

## Decision

Use Sidekiq to send emails and other asynchronous tasks.

Use Redis as the queue for jobs to improve fault resilience.

## Consequences

We will need a new Redis dependency and a new Sidekiq process running in environments. This is a short term cost but will enable other future jobs to be added easily. 

Sending emails asynchronously will provide some fault tolerence if Notify is unavailable or if there are any other connectivity issues.
