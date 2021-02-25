# 30. Run data migrations manually

Date: 2021-02-24

## Status

Accepted

## Context

The Data Migrate gem has caused us a number of issues in the past, it runs
silently as part of a deploy, and this can result in surprising errors
during a deploy. We've also had issues with the gem itself - most recently
a bug in a new version causing strange errors in deployment.

## Decision

With this in mind, we've decided to drop the use of the Data Migrate gem,
and instead run any data migrations manually. We have easy access to the
console via GOV.UK PaaS, so this is relatively painless.

We have added a generator which creates an empty Ruby file with a timestamp and the name of the migration as the filename. Once the code is
deployed, we run the migration on the production server.

As the code is plain old Ruby, it's also easier for us to write tests, if
we think it's worth doing (for example, the migrations code is suitably
complex).

## Consequences

Data migrations now become a deliberate act. It's no longer "fire and
forget", and we have to remember to run the migrations on the remote
server. We agree this is a sensible way forward though, as is means we have
to be more cautious when making changes to production data.
