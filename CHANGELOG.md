# Change Log

## [release-1] - 2020-03-04

- Add Google Tag Manager in place of templated Google Analytics code
- Ensure missing I18n strings cause tests to fail
- Users can be created/updated both locally and in Auth0
- Users can be associated with multiple organisations
- Allow roles to be assigned to users
- Users are welcomed and able to create their new password to access the service
- Service name updated from "Overseas" to "Official"
- Users can create and view Funds; users can create and view Activities
- Users can download an XML representation of an Activity
- Split activity form into multiple steps
- Create Transactions associated with a Fund
- Remove the distinction between Fund and Activity from the user
- Users can edit an organisation
- Users can edit the basic fund record
- Users can edit a transaction
- Users can edit an activity record
- Transactions record the provider and receiver organisations
- All forms now use `govuk_design_system_formbuilder` instead of `simple_form`
- Activity multi-step form now has validations
- Users can view an XML representation of Transactions and Funds
- Force SSL in production environments
- A users role can be viewed, set and changed
- Restrict delivery partners so they can only view and edit their own organisation
- Fund managers can manage users, organisations, funds, fund activites and fund transactions
- Transaction and Activity dates are restricted to 10 years in the past or 25 years in the future at most
- Provide a way to flag an organisation as BEIS
- User email addresses must be valid emails
- Users are only associated with one organisation
- Users land on their organisation#show page when they log in, instead of a "dashboard"
- Fund manager can add a programme level activity to a fund level activity
- Fund manager can view a fund level activity's programme activities
- Fund managers can create Budgets
- Fund and Programme activities store funding organisation details
- Fund and Programme activities store accountable organisation details
- Fund activities store extending organisation details
- Sign in button works when JS is disabled
- Fund managers can set and change the extending organisation
- Date inputs in forms for creating activity, transaction and a budget have a hint text
- Transaction provider and receiver IATI references are exposed in the XML if present
- Users can report project level activities
- Users can add budgets to project level activities
- Users can view Budgets in the Activity XML
- Consolidate all user roles into 'administrator', removing 'fund_manager' and 'delivery_partner'. All users can temporarily do anything
- Users who belong to delivery partners see a list of programmes on their organisation page
- Users are authorised based on the organisations they belong to
- Users can add budgets to activities at all levels
- Users can edit a budget
- Users can add currency information to budgets and see the currency in the budget XML
- Users can report an activities implementing organisation
- Users can edit a reported implementing organisation
- Users can view implementing organisations in the Activity XML
- Planned start and end dates are mandatory
- Actual start and end dates must not be in the future

## [release-2] - 2020-03-12

- Activity status is now shown as radio buttons with hints
- Activity XML includes 'iati-identifier' which is includes the reporting organisation
- Activity XML includes 'iati-identifier' with an identifier that consists of all present levels of hierarchy: fund and/or programme
- BEIS users (administrators) can mark other users as active or inactive
- Budget start and end dates are validated according to IATI standard
- BEIS users can view projects (read-only) and download them as XML via a button
- Codelist dropdowns do not contain values which have been marked as "status: withdrawn" by IATI
- Redis version increased from 3.x to 4.x now that GPaaS supports it
- Users can report either recipient_country or recipient_region data which is
  include in the xml

## [release-3] - 2020-04-02

- Activities are ordered by `created_at` date, oldest first
- Transactions are ordered by `date`, newest first
- Budgets are ordered by `period_start_date`, newest first
- Remove transaction description from the transaction display table, to improve the activity page UI
- Organisation and User management links are in the site header navigation
- Organisations are managed from the /organisation page
- Organisation show page re-organised to show more information including funds,
  programmes and projects for the relevant users
- Make it clearer that Programme should have an extending organisation in order
  for delivery partners to report on the programme
- fix cookie error by switching session storage to Redis
- Activity aid type is now selected by radio button, not a dropdown select box
- Iterate the form content for the sector field by renaming it to "focus area"
- Enable host whitelisting (Rails 6 feature) to mitigate poisoned host header attacks
- Anonymize user's IP addresses before logging them outside the application, by removing the last octet of the address. Also use Rollbar's built-in IP address anonymizer.
- BEIS users can view Transactions & Budgets on a project, but not create or edit them
- Country list for recipient countries when creating an activity has been reduced to only those ODA uses as recipients.
- Add feedback form link to phase banner

## [release-4] - 2020-04-09

- When creating an activity the Finance step has been defaulted to `Standard grant` and omitted from the user journey
- When creating an activity, the `Tied status` step has been removed from the user journey and it has now a default value of `Untied`, code "5"
- Progressively enhance the country select element into a combo box when
  Javascript is available
- Add privacy policy to site
- Empty optional dates for `actual start date` and `actual end date` are not included on the activity XML
- Reporting org in the IATI XML is always BEIS for funds, programmes and projects created by governmental organisations, and the activity's organisation if it is a non-governmental organisation

## [release-5] - 2020-05-07

- User actions are tracked on Activities, Budgets, Transactions and Users.
- Activities that have an identifier already can use it as the iati-identifier
  in the xml output
- User actions are tracked on Organisations.
- Individual Activity update steps are tracked on create & update
- Content added to start page
- Links that open in a new window now have a message informing the user of this.
- BEIS users only see an organisation's activities on that organisation's show page (bug)
- XML file for projects now shows the identifiers for the parent activities.
- Fix descriptive labels on action links
- Remove `reference` from Transactions
- Add level D activities (third-party projects)
- Store Budget status and type as numbers, not words
- Delivery partner users can view budgets on Level B activities (but not edit or create them)
- Show a funds programmes in a table

## [release-6] - 2020-05-19

- Transaction and budget values are validated down to 0.01
- Add Skylight application performance monitoring
- Script to ingest legacy IATI data
- No longer show the geography response on the activity summary and when changing country or region the flow includes the geography question
- Add concept of `ingested` to budgets, and skip validation on ingested budgets. This is in preparation for ingesting legacy data from IATI.
- Sector questions asks for a category and uses radio buttons
- Add concept of `ingested` to transactions
- Transaction disbursement channel is no longer mandatory
- IATI ingest tool now saves the original XML for each activity to enable future tasks to copy across additional fields
- User can add, view and edit planned disbursements to projects and third-party projects
- BEIS users can download all of an Organisation's project (or third-party project) activities as XML from the organisation show page

## [release-7] - 2020-06-01

- Ingest tool no longer creates programmes but is instructed to look for existing records
- If an activity has a recipient_country set, the recipient_region is inferred from the recipient_country
- Planned disbursements are exported in the IATI XML
- The new planned disbursement form pre-fills the providing organisation details
- Add cookie policy
- Planned disbursement dates are validated within boundaries
- Ingest tool creates or updates existing projects if they match on the IATI identifier
- Ingest tool will try to set more meaningful identifiers for projects
- The providing organisation is pre-filled in for new transactions
- No longer lint the automatic schema changes made by the data_migrate gem
- Switched to the latest form builder gem version from our fork
- Planned disbursement create and update actions are recorded
- User role hint text is shown
- Transaction dates are validated to be no more than 10 years ago and 25 years
  in the future

## [release-8] - 2020-06-04

- The IATI identifier on an activity, transaction, planned disbursement,
  organisation and implementing organisation  is stripped of leading and
  trailing whitespace
- Header navigation follows GOVUK frontend pattern
- Infer a transaction's and planned disbursement's `receiving-org type` from its
  parent activity's `implementing organisation`, if the `receiving-org type` on the
  element is missing
- Ingest tool fails loudly if any activity fails to be created
- Ingest UKSA data from IATI

## [release-9] - 2020-06-18

- Transactions can have a negative value (but not zero)
- Amend Activity date validations - either `planned_start_date` *OR* `actual_start_date`
  must be present, in line with the IATI `activity-date` XML standard
- Amend ingest service to successfully ingest Activities without an `activity-date` type
  2 (`actual_start_date`)
- Ingest AMS Newton fund data from IATI
- Flag incomplete activities in the activity table views
- XML download does not contain any incomplete activities
- XML download contains a `narrative` element for region & country containing the region or country name
- Ingest AMS GCRF data from IATI
- When a programme has an extending organisation set, the same organisation is set as the implementing organisation
- Use the `lograge` gem to reduce logging in production

## [release-10] - 2020-06-30

- Users can see codes when selecting aid type
- Content changes to activity status field
- Content changes to activity title field
- Content changes to activity purpose field
- Remove 3 unwanted activities from production
- Content changes to fields for transaction value and activity identifier
- Increase the width of the application layout

## [release-11] - 2020-07-08

- Ingest RS Newton fund data from IATI
- Allow BEIS users to redact activities from the IATI XML file, and to
  easily see on the Organisation show page which Activities are redacted
- Activity show content is show in tabs for financials and details
- Refactor how we can ask activities for their parents
- Ingest BA Newton fund data from IATI

## [unreleased]

- Activity identifiers are unique among siblings
- add accessibility statement
- Move budgets to the top of the programme activity financials tab
- Activity XML includes only recipient-country OR recipient-region, not both
- Activity creation journey changed to ask for a level and parent
- Add an activities page and navigation
- Activities can be filtered to an organisation

[unreleased]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-11...HEAD
[release-11]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-10...release-11
[release-10]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-9...release-10
[release-9]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-8...release-9
[release-8]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-7...release-8
[release-7]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-6...release-7
[release-6]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-5...release-6
[release-5]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-4...release-5
[release-4]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-3...release-4
[release-3]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-2...release-3
[release-2]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-1...release-2
