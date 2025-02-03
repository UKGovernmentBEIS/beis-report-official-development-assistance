# 40. Use sidekiq-scheduler for scheduled jobs

Date: 2025-02-03

## Status

Accepted

## Context

We needed a mechanism for running scheduled background jobs in order to
anonymise users who have been inactive for more than five years. There is no
mechanism currently in place in RODA to handle scheduled background jobs, but
we do have Sidekiq already available to us for running jobs in the background.

## Decision

We have decided to use [sidekiq-scheduler][1] as a lightweight scheduled job
solution. A small amount of research suggested that this gem offered a decent
implementation with a standard and well-understood interface (the time-honoured
cron syntax combined with Sidekiq's jobs (_né_ workers)). We also briefly
explored [sidekiq-cron][2] which does almost exactly the same thing, but had
slightly worse documentation.

## Consequences

With the addition of this gem, we have a small amount of configuration overhead
and, of course, one additional dependency. Neither of these is particularly
onerous. We now benefit from having a standardised solution for our current
and future scheduled background job requirements.

[1]: https://github.com/sidekiq-scheduler/sidekiq-scheduler
[2]: https://github.com/sidekiq-cron/sidekiq-cron
