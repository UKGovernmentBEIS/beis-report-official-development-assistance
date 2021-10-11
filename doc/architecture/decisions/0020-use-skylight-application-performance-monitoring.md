# 20. use-skylight-application-performance-monitoring

Date: 2020-05-01

## Status

Superceded by [32. remove skylight](0032-remove-unused-skylight-performance-monitoring-app.md)

## Context

To ensure the RODA application has the highest availability, we want 
to have confidence that the application is resourced properly in times of 
low and high usage.

## Decision

dxw have used the Skylight gem in many other projects and there is a Skylight
account available for use. We have prior knowledge of using Skylight in
other projects.

Skylight provides a web interface and graphing so we can more easily identify
pain points in our application which will cause it to become less performant
under high load. It can identify slow-running parts of the service down to the
controller action level, and indicate where - for example - excessive database
calls or slow queries are causing degradation in the user's experience.

Common alternatives to Skylight are New Relic and DataDog. We do have some
experience with DataDog at dxw, but we had more confidence within the team with
using Skylight.

## Consequences

Skylight will turn performance data from our application into insights which we
can use to make product decisions. Identifying pain points in advance of the
application being put under high loads means we can have more confidence
in the application's performance in public beta and live.
