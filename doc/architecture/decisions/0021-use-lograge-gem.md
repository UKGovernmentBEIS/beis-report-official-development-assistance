# 21. use-lograge-gem

Date: 2020-06-16

## Status

Accepted

## Context

RODA uses Papertrail for logging. Our Papertrail account has a log data
transfer limit of 50 MB. Extending this limit means moving to another tier
on Papertrail's platform, which we would prefer to avoid.

## Decision

- Reduce the default logging level on production to `info` instead of `debug`
- Use the [lograge gem](https://github.com/roidrage/lograge) to turn Rails'
  default multiline logs into a single line, without losing information or
  context

## Consequences

Our Papertrail usage will be reduced with no loss of critical information.

