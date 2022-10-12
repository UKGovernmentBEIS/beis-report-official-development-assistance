# 13. travis-only-tests-with-docker-containers

Date: 2019-12-19

## Status

Accepted

## Context

We noticed that deployments to staging were silently failing since a gem update that succeeded in Travis did not succeed in our docker environment, where docker is used on our live environment.

dxw have a default stance to test with containers where we host with containers: https://github.com/dxw/tech-team-rfcs/blob/main/rfc-013-use-docker-to-deploy-and-run-applications-in-containers.md


## Decision

Travis uses Docker containers to test the application on every build and deploy.

## Consequences

We can worry less about the parity between travis and docker environments to catch bugs sooner.
