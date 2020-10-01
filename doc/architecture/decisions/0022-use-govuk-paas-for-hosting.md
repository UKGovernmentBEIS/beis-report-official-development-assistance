# 22. use-govuk-paas-for-hosting

Date: 2020-10-01

## Status

Accepted

Supercedes [8. use-heroku-for-hosting](0008-use-heroku-for-hosting.md)

## Context

As a government entity, BEIS want to host their service on [GOVUK
PaaS](https://www.cloud.service.gov.uk/). This was always the service teams
intention.

## Decision

Host all environments excpet local development on BEIS own GOVUK PaaS account.

## Consequences

The dxw team will need access to the GOVUK PaaS account.

The service will need to be migrated to GOVUK PaaS, using containers for
deployments will aid this.

The ownership and responsibility for the GOVUK PaaS account is with BEIS.
