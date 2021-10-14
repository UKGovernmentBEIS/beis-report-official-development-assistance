# RODA documentation

## The RODA application

- **[Glossary of terms (glossary)](./glossary.md)**

- **[Activity CSV Importer
  (activity-csv-importer.md)](./activity-csv-importer.md)**: We need to import
  legacy data for delivery partners, so they don't have to manually re-key it
  into RODA.

- **[Activity Identifiers
  (activity-identifiers.md)](./activity-identifiers.md)**: RODA maintains four
  different types of identifier for activities.

- **[Benefitting countries and regions
  (benefitting_countries_and_regions.md)](./benefitting_countries_and_regions.md)**:
  The countries an activity is seen to benefit is one of the primary factors
  that make the activity eligible for ODA funding.

- **[Exports (exports.md)](./exports.md)**: Spending Breakdown: a report
  primarily aimed at BEIS finance needs; also (**TO DO**) Report Export:
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

- **[Console access (console-access.md)](./console-access.md)**: You must have
  an account that has been invited to the Government Platform as a Service
  (GPaaS) account.

- **[Database backup and restore
  (database-backup-and-restore.md)](./database-backup-and-restore.md)**:
  Postgres instances are hosted within GPaaS and exist as backing services.

- **[Background jobs (background-jobs.md)](./background-jobs.md)**: We use use
  Sidekiq (backed by Redis) to handle sending emails

- **[Identifying invalid activities (utilities.md)](./utilities.md)**: A rake
  tasks to report invalid activites in a CSV file.

  **[Importing commitments (import-commitments.md)](./import-commitments.md)** A
  rake task to import Commitments into the application

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
  Environment variables are passed to live environments through Terraform by
  either Github Actions or a manual deployment.

- **[Create new reports
  (support_tasks/create_new_report.md)](./support_tasks/create_new_report.md)**:
  Manually create a new report, most commonly required when a new delivery
  partner joins ODA reporting.

- **[Reset a user's MFA
  (support_tasks/reset_mfa.md)](./support_tasks/reset_mfa.md)**:
  Reset a user's multi-factor authentication settings, so that they can configure a new method, e.g. if they have a new mobile phone number.

- **[Pull back a submitted report (support_tasks/pull_back_submitted_report.md)](./support_tasks/pull_back_submitted_report.md)**:
  Allow a delivery partner to resume editing a submitted report.

- **[Change a report's financial period (support_tasks/change_financial_period.md)](./support_tasks/change_financial_period.md)**:
  If a report is created with the wrong financial period it is a little fiddly to change.
