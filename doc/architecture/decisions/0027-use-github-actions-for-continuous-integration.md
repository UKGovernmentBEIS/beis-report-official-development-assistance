# 27. Use Github Actions for Continuous Integration

Date: 2020-12-18

## Status

Accepted

## Context

We have used Travis CI for Continuous Integration and deployment since the start
of this project (see [005](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/develop/doc/architecture/decisions/0005-use-travis-for-ci.md)), but due to changes in the business model of Travis, we
now have to pay for builds to be run, and the service we do pay for is slow, and
holding up the pipeline of work we can deliver.

Github Actions has been in operation for a good while now, and is a mature and
stable product. It also supports all the tools we currently use on Travis, so
is easy to migrate across. We can also cache our Docker containers, speeding up
build time considerably.

## Decision

Move Continuous Integration from Travis CI to Github Actions, and remove our repo
from Travis CI.

## Consequences

We will no longer have to sort out payment for Travis CI via BEIS.
