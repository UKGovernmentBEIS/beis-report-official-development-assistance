# 8. use-heroku-for-hosting

Date: 2019-10-13

## Status

Superceded by [22. use-govuk-paas-for-hosting](0022-use-govuk-paas-for-hosting.md)

## Context

During the set up phase of the beta we investigated what the long term hosting should be. This was agreed to be Government's Platform as a Service (GPaaS) as it was the strategic platform all other digital services within BEIS were moving to.

We have been unable to get access to the BEIS GPaaS account to set up the platform.

We value having a real service hosted as soon as possible and would like to have this done in the first few sprints so the team have a live product to iterate.

## Decision

Use dxw's Heroku account to host a staging and production environment and migrate the service to GPaaS later.

## Consequences

We will pay more to use Heroku in the short term but set up will be simple. We will not need to invest too much time early on on platform that may need to be repeated in future.

A migration to GPaaS will eventually happen. We have flagged the risk to the deputy directory of BEIS digital and how this risk increases the more complex the service becomes, and when real users start using the service.

We should be concious of investing too much time in the Heroku setup to avoid repeating ourselves.

We will use containers to deploy to Heroku to aid in a stable migration, as GPaaS also supports containers now.
