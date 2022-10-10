# 33. Move towards more continuous delivery

Date: 2021-11-09

## Status

Accepted

## Context

During recent months we've been deploying new code to production on Tuesdays and
Thursdays. This has been in order to allow BEIS to communicate changes in RODA
to Delivery Partners and avoid causing confusion with a service which is changing
"under their feet". This Tuesday/Thurs release routine has been a convention
rather than a rule, as sometimes there have been urgent fixes which we've
deployed as soon as possible, to everyone's satisfaction.

We are now moving out of a "development" phase, where we have full-time
developers with deep context of the system, into a "support/operations" phase
where updates and fixes will be applied on an adhoc basis.

## Decision

We will remove the convention of deploying only on Tuesdays and Thursdays in
recognition that it will now often be most efficient to deploy new code as soon
as it's been tested and approved for release.

Existing conventions around preparing a clear ChangeLog (see 
[ADR 0007](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/main/doc/architecture/decisions/0007-use-a-changelog-for-tracking-changes-in-a-release.md#L26))
and communicating releases via Slack will remain unchanged.

Deployments will now be made regularly at the discretion of the team.

## Consequences

Communication around releases, principally via the Slack channel, will now be of
increased importance.

The team may want to consider whether any elements of the 
[deploy-process](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/main/doc/deployment-process.md)
can be streamlined or automated to make the process of tagging a release and preparing the ChangeLog faster.

