# 32. remove-unused-skylight-performance-monitoring-app

Date: 2021-10-06

## Status

Supercedes [20. use-skylight-application-performance-monitoring](0020-use-skylight-application-performance-monitoring.md)

## Context

We've had the Skylight profiler app installed since May 2020. However, it's not
been used for a long time and in fact has been misconfigured for as long as any
one can remember. Should we invest further, at this point, in a service which is
not being used, or should we remove it for now?

## Decision

We opt to remove the Skylight service, for the following reasons:

- using the git history we can readily re-instate it
- it's not currently used and is an overhead to maintain
- it's currently misconfigured
- we are currently moving out of our development phase into an
  operational/support phase and are transferring ownership of all third party
  services to BEIS

## Consequences

For now RODA has fewer dependencies. We recognise the gap in performance monitoring.

It's entirely possible that as part of our coming work with the dxw operations
department, as we move into operational mode, we may choose to reinstate the
profiling, perhaps to configure automated alerts.
