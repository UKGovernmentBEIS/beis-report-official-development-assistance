[![Build Status](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/workflows/CI/badge.svg?branch=develop)](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/actions?query=branch%3Adevelop)
[![Coverage Status](https://coveralls.io/repos/github/UKGovernmentBEIS/beis-report-official-development-assistance/badge.svg?branch=develop)](https://coveralls.io/github/UKGovernmentBEIS/beis-report-official-development-assistance?branch=develop)

# Report Official Development Assistance (RODA)

This service enables the Department for Business, Energy and Industrial Strategy
(BEIS) and their partner organisations to collect and report information on the
spending of Official Development Assistance (ODA).

In February 2023 BEIS became the Department for Science, Innovation and
Technology (DSIT), which had a large impact on the application. You will
see references to both organisations in both the code and the data, and this is
worth keeping in mind as you work on the application.

## Environments and hosting
All environments are hosting on AWS provided by DSIT, for more details see the
[hosting documentation.](/doc/hosting.md)

To access the environments you will need a `digital-paas-prodction-account`
account and then [assume the correct role](/doc/hosting.md#assuming-roles) for
each environment.

### Environments

- [Development](https://dev.report-official-development-assistance.service.gov.uk)
- [Staging](https://staging.report-official-development-assistance.service.gov.uk)
- [Training](https://training.report-official-development-assistance.service.gov.uk)
- [Production](https://www.report-official-development-assistance.service.gov.uk)

## Getting started

If this is your first time running the application, see the [getting started
documentation](/doc/getting-started.md) for instructions.

You will likely need access to the environments, see the [hosting
documentation](/doc/hosting.md) on how to obtain this.

## Support documentation

- [Deleting activities from
  production](/doc/support/deleting-activities-production.md)
- [Reset a user's MFA](/doc/support/reset_mfa.md)
- [Pull back a submitted report](/doc/support/pull_back_submitted_report.md)
- [Change a report's financial period](/doc/support/change_financial_period.md)
- [Add _channel of delivery_ code to the accepted
  list](/doc/support/add_accepted_channel_of_delivery_code.md) 
- [Downoload activies for annual impact
  metrics](/doc/support/download_activities_for_annual_impact_metrics.md)

## In-depth documentation

- [Glossary of business terms](/doc/glossary.md)
- [Hosting](/doc/hosting.md)
- [Deployment](/doc/deployment-process.md)
- [Logging](/doc/logging.md)
- [Environment variables](/doc/environment-variables.md)
- [Sending email notifications](/doc/email-notifications.md)
- [Use authentication](/doc/authentication.md)
- [Importing new partner organisation
  data](/doc/importing-new-partner-organisation-data.md)
- [Activity identifiers](/doc/activity-identifiers.md)
- [Benefitting countries and regions](/doc/benefitting_countries_and_regions.md)
- [Exports](/doc/exports.md)
- [Forecasts and versioning](/doc/forecasts-and-versioning.md)
- [Internationalisation](/doc/i18n.md)
- [Pattern library](/doc/patterns.md)
- [IATI XML Validation](/doc/xml-validation.md)
- [Importing commitments](/doc/import-commitments.md)
- [Identifying invalid activities](/doc/utilities.md)
- [Background jobs](/doc/background-jobs.md)
- [Console access](/doc/console-access.md)
- [DNS](/doc/dns.md)
- [Migrations](/doc/migrations.md)

## Errors and monitoring

### Errors

We send errors to a dxw owned [Rollbar
project](https://rollbar.com/dxw/dsit-roda/), contact dxw support to get access.

## Architecture decision records We use ADRs to document architectural decisions
We use ADRs to document architectural decisions that we make. They can be found
in doc/architecture/decisions and contributed to with the
[adr-tools](https://github.com/npryce/adr-tools).

