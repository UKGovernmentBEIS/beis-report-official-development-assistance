# RODA documentation

## The RODA application

- **[Glossary of terms (glossary)](./glossary.md)**

- **[Authentication](Authentication.md)**: Details about authentication and 2FA.

- **[Importing new partner organisation data
  (importing-new-partner-organisation-data.md)](./importing-new-partner-organisation-data.md)**: We need to import
  legacy data for partner organisations, so they don't have to manually re-key it
  into RODA.

- **[Activity Identifiers
  (activity-identifiers.md)](./activity-identifiers.md)**: RODA maintains four
  different types of identifier for activities.

- **[Benefitting countries and regions
  (benefitting_countries_and_regions.md)](./benefitting_countries_and_regions.md)**:
  The countries an activity is seen to benefit is one of the primary factors
  that make the activity eligible for ODA funding.

- **[Exports (exports.md)](./exports.md)**: Spending Breakdown: a report
  primarily aimed at DSIT finance needs; also (**TO DO**) Report Export:
  detailing the information communicated in a given Report

- **[Forecasts and versioning
  (forecasts-and-versioning.md)](./forecasts-and-versioning.md)**: Forecasts
  represent plans or predictions about money that will be spent in the future.

- **[Internationalisation (i18n.md)](./i18n.md)**: How RODA used locale file and
  Rails 'internationalisation', including the conventions which come with the
  GOVUKDesignSystemFormBuilder system.

- **[Pattern Library (patterns.md)](./patterns.md)**: How RODA uses "accessible
  action links".

- **[IATI XML Validation (xml-validation.md)](./xml-validation.md)**:
  Information about IATI's XML validation.

## Operations

- **[Deployment process (deployment-process.md)](./deployment-process.md)**: A
  step-by-step playbook to preparing and deploying a production release.

- **[Logging (logging.md)](./logging.md)**: Logging for services into Papertrail.

- **[Console access (console-access.md)](./console-access.md)**: You must have
  an account that has been invited to the Government Platform as a Service
  (GPaaS) account.

- **[Background jobs (background-jobs.md)](./background-jobs.md)**: We use
  Sidekiq (backed by Redis) to handle sending emails.

- **[Identifying invalid activities (utilities.md)](./utilities.md)**: A rake
  task to report invalid activities in a CSV file.

- **[Importing commitments (import-commitments.md)](./import-commitments.md)** A
  rake task to import Commitments into the application.

## Third party services

- **[Email notifications (email-notifications.md)](./email-notifications.md)**:
  The application sends various notifications by email using GOV.UK Notify


## Support tasks

- **[Deleting Activities from Production
  (deleting-things-from-production.md)](./deleting-things-from-production.md)**:
  Users cannot delete activities via the web app. Requests to delete activities
  usually come in via Zendesk support tickets.

- **[Manage environment variables
  (manage-environment-variables.md)](./manage-environment-variables.md)**:
  Environment variables are stored in AWS ParameterStore.

- **[Reset a user's MFA
  (support_tasks/reset_mfa.md)](./support_tasks/reset_mfa.md)**:
  Reset a user's multi-factor authentication settings, so that they can configure a new method, e.g. if they have a new mobile phone number.

- **[Pull back a submitted report (support_tasks/pull_back_submitted_report.md)](./support_tasks/pull_back_submitted_report.md)**:
  Allow a partner organisation to resume editing a submitted report.

- **[Change a report's financial period (support_tasks/change_financial_period.md)](./support_tasks/change_financial_period.md)**:
  If a report is created with the wrong financial period it is a little fiddly to change.

- **[Add "channel of delivery" code to the accepted list (support_tasks/add_accepted_channel_of_delivery_code.md)](./support_tasks/add_accepted_channel_of_delivery_code.md)**:
  From time to time an additional IATI "channel of delivery" code needs to be
  added to RODA's list of accepted codes.
