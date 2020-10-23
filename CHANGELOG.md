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

## [release-12] - 2020-07-28

- Activity identifiers are unique among siblings
- add accessibility statement
- Move budgets to the top of the programme activity financials tab
- Activity XML includes only recipient-country OR recipient-region, not both
- Activity creation journey changed to ask for a level and parent
- Add an activities page and navigation
- Remove Back links, except on the Activity form
- Refactor the activity update action
- Replace generic Rails error pages with styled pages (404, 500 and 422)
- Activities can be filtered to an organisation
- Selecting an activity level now includes more explanation of the hierarchy
- Activities show their child activities in a tab
- Activities link to their parent activity in the details tab
- Add Submission model, tests and fixtures. Seed database with a Submission per
  Organisation/Fund pair. Show a basic Submission table on the user's home page.
- Fund, programme, project and third-party project activities are no longer
  shown on the home page
- Submission descriptions can be edited. A deadline attribute has also been added
  to the Submission model; setting a deadline moves the Submission into the "active"
  state
- Migrate UKSA GCRF activities from Level C to Level D
- Add new `transparency_identifier` field which will be the identifier used in the
  IATI XML. This field is non-editable.

## [release-13] - 2020-08-05

- Allow budgets to have a negative value (but not zero)
- Customise error messages according to the content review
- Add a very basic Submission show page and CSV skeleton
- Migrate AMS GCRF activities from Level C to Level D

## [release-14] - 2020-08-21

- Associate Transactions to Submissions
- Export Activity data in the Submission CSV
- rename Submission to Report
- reports can be managed in the reports section of the application
- remove submission from the organisation page
- Add `transactions_total` to Activity and add it to the Submission CSV per Activity
- Migrate AMS GCRF activities from Level C to Level B and update identifiers
- Ingest creates new activities at a level below its parent
- Reports store the relevant financial quarter
- Associate Planned Disbursements to Reports
- Update extending organisation question content
- `programme status` field added to activity form in exchange for old IATI status.
  Mapping `programme_status` to `IATI_status` included. Schema migration to replace
  `form_state` at `status` step for `programme_status` step
- `programme status` form step is not shown for level A activities
- Scope the total transaction value for an Activity to a Report and that Report's date
  range, and call the result `actual_total_for_report_financial_quarter`. Add this
  value to the Report CSV.
- Calculate the total of all Planned Disbursements in a Report's date range as
  `forecasted_total_for_report_financial_quarter` and output the value to the Report CSV
- Ingest RAEng Newton fund data from IATI

## [release-15] - 2020-09-03

- Reports can be submitted
- Submitted reports are shown to users
- Reports can be activated explicitly
- Inactive reports are shown in their own table on the reports page
- Reports are no longer activated when the deadline is set
- Calculate the variance between an Activity's transactions total for a date range, and
  that same Activity's planned disbursements total for a date range. Output this value
  to the Report CSV as "Variance"
- Find the next four financial quarters after this report's financial quarter. Find the
  forecasted totals (planned disbursement totals) for those four future quarters and output
  them to the report CSV
- Submitted reports can be moved into the review state
- Reports in review can be moved into the awaiting changes state
- Transactions & Planned Disbursements cannot be edited if they are associated with an approved Report
- BEIS users can move a Report into the approved state
- `Call open date` and `Call close date` added to the create activity form, for levels C and D.
  This field is mandatory for new activities, but optional for activities marked as `ingested: true`
- `Create activity` buttons that were not changed on previous PR, are changed to
  `Add activity` now.
- RODA Identifiers can be added to activities on creation and when updating
- Reports in 'awaiting changes' can be submitted.
- Forecasted and actual spend and variance is shown on the report show page
- Ingest RS GCRF data from IATI
- Ingest BA GCRF data from IATI
- Ingest RAEng GCRF data from IATI
- Transparency Identifiers are set based on RODA Identifiers
- Delivery Partner Identifiers can be edited

## [release-16] - 2020-09-09

- Reports no longer have to be unique
- Reports cannot be unique for the Level A activity
- Add empty states for report tables
- Show Level A (Fund), organisation and financial quarter on the report edit
  page
- Handle attempts to activate invalid reports
- `Recipient_region` codelist modified
- `Intended beneficiaries` form field added, including validations, and country to region mapping
- `ODA eligibility` form step added to create activity journey
- Update any ingested Level B activities that do not have the BEIS organisation as their
  associated organisation. All Level B activities should belong to BEIS.
- `GDI` form step added to create activity journey
- Show Aid Type and Sector codes in Report CSV export for activities
- Update activity policy to account for the report state

## [release-17] - 2020-09-18

- New reports are created when the prior is approved
- `Total applications` and `Total awards` form step added to create activity journey
- Report deadline value is shown on the edit form
- Change on hierarchy terminology to display activity levels A, B, C and D along with old terminology in the UI across the service
- Update on the definitions for each level of activity
- Updated transaction policy
- Only show the edit transaction link when the transaction can be edited
- Only show the add transaction button when the activity can be edited
- Updated planned disbursement policy
- Only show the edit planned disbursement link then it the planned disbursement
  can be edited
- Only show the add planned disbursement button when the activity can be edited
- BEIS users can add transactions regardless of report state
- BEIS users can add planned disbursements regardless of report state
- Update the activity financials view to show all financials on all levels
  except Funds (Level A)
- Delivery partners can create & update comments associated to an activity & a report
  The comments are exported to the report CSV
- For delivery partners, Budgets relate to the report that creates them
- Ingest can handle the new budget/report relationship
- Update the budget policy
- Report variance is shown in a tab
- Show budgets added in a report on the reports view
- `Collaboration type` form field added to create activity journey and activity XML
- Upload transaction data in bulk as CSV
- Display the parent activity's RODA identifier when adding RODA IDs
- Missing `West Bank and Gaza Strip` country included in `recipient_country` list
- Report state content updated

## [release-18] - 2020-09-25

- Add and amend Activity data fields in the Report CSV export
- Accept strictly numeric values in the `Value` column for bulk transaction
  import
- Do not automatically strip letters from numeric value fields; instead reject
  the values as invalid and show an error to the user
- the sign out navigation link is not active on the users page
- BEIS users can download IATI XML for programmes (level B)

## [release-19] - 2020-10-02
- The user type is tracked in Google Analytics
- `providing_organisation_reference` is set when the user uploads transactions
- Separate the list of intended beneficiaries in the report CSV with semicolons
- Users can now edit fields on invalid completed activities

## [release-20] - 2020-10-06
- Fix bug that prevented delivery partners from submitting a report.

## [unreleased]
- Collect financial quarter and year for planned disbursements (forecasts)
  instead of start and end dates (the values of which are calculated).
[unreleased]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-20...HEAD
[release-20]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-19...release-20
[release-19]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-18...release-19
[release-18]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-17...release-18
[release-17]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-16...release-17
[release-16]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-15...release-16
[release-15]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-14...release-15
[release-14]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-13...release-14
[release-13]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-12...release-13
[release-12]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-11...release-12
[release-11]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-10...release-11
[release-10]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-9...release-10
[release-9]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-8...release-9
[release-8]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-7...release-8
[release-7]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-6...release-7
[release-6]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-5...release-6
