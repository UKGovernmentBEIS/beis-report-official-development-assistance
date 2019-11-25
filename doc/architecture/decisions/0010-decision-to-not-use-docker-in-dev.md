# 10. decision-to-not-use-docker-in-dev

Date: 2019-11-25

## Status

Accepted

## Context

dxw do not set a preferred default for working in development. dxw do set a default stance of using docker in all live environments and CI.

Docker in development can be slow and it can require some experience to resolve situations where things go wrong, like a full disk space.

## Decision

Use non-docker tools and packages to run the application in development. This includes web servers, rails consoles, tests, local dependencies eg, Sidekiq, NPM, etc.

## Consequences

The current development team will be more productive using tools they are more comfortable with.

Getting the app set up on your local machine requires a longer process. There is more room for problems when setting up and starting several dependencies locally. We could automate this using Foreman or Make files.

Support teams who are rotated on will have to spend time going through the documentation to get set up before they can work on any issues.

We may have to come back later to add Docker Compose.

Debugging issues found on live environments on our local environments can be harder without the parity. We could add Docker Compose files if these edge cases come up but they will not be readily available.

Documentation for getting set up locally has more chance of being maintained compared to if there were 2 different options used by different team members. It is harder to keep to sets of documentation up to date.
