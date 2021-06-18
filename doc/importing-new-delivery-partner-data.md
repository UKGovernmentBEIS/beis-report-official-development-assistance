# Importing delivery partner data to the application

## General
We have enough confidence in our code to run this as a pair on production.

If you want to gain confidence about any aspect and would get that by running
the import locally first, feel free to do so. Running the import locally lets
you get the data into perfect shape before you have to copy it over to
production.

All imports are run in a transaction, if any row fails the whole import is
skipped.

Once all the data is imported, zip up the actual files used and attach them to
the Trello card (see below), this keeps a record of what might have been
modified for the import and the original files.

## Cards and source files
We have a Trello card for each import to be run for each

- delivery partner organisation
- fund

All of the files will be attached to the card:

For Newton fund:

- level B activity, actual spend and forecast data
- level C activity, actual spend and forecast data
- actual spend data pre formatted for import (no longer used and can be ignored)

For GCRF:

- level B activity, actual spend and forecast data
- level C activity, actual spend and forecast data
- level D activity, actual spend and forecast data
- actual spend data pre formatted for import (no longer used and can be ignored)

Pick up a card as a pair and move it to 'in progress'.

The steps below should be followed in order as they are dependent on each other.

## Activity

Import activities in order:

1. Level B
2. Level C
3. Level D

### Checking activity data

- are the headers correct? Use the migration template to verify.
- are the values coded correctly? Use the migration template to verify.
- are any values missing? The import will give you errors but look for anything
  obvious.
- raise any issues as soon as you can in Slack, the sooner we know the soon we
  can work together to rectify them.

### Prep activity data

- correct any headers
- for GCRF activities add a column `UK DP Named Contact` and set all rows to
  `Must be provided`
- add any missing values if possible - if not raise the issue in Slack
- save as UTF8 csv file

### Import activity data in production

You will need your user account to be associated to the delivery partner
organisation for which you are running the import. You will also need to note
this organisation ID to run the import.

- copy the file over to production

```
cat FILENAME.csv | cf ssh beis-roda-prod -c "cat > FILENAME.csv"
```

- find the id of the `Organisation` that the import is for i.e. the Delivery Partner
- connect to production:

```
cf login
cf ssh beis-roda-prod
```

- run a rails console

```
bin/rails console
```

- locate your account

```
me = User.find_by(email: youremail)
```
- locate the organisation id you want

```
Organisation.all.pluck(:name, :id)
```

- update your user

```
me.update(organisation_id: "organisation_id")
```
- quit the console

- run the import

```
bin/rails activities:import CSV=FILENAME ORGANISATION_ID=ORGANISATION_ID UPLOADER_EMAIL=youremail
```

- smoke test the activities in production after each level is imported

## Reports

We do not import reports, but the forecasts and actual spend require the correct
active report in order to run successfully.

We have made the decision to run the import as though the data was collected in
FQ3 2020-2021 (1 Oct 2020 – 31 December 2020)

### Create the report

- connect to prod:

```
cf login
cf ssh beis-roda-prod
```

- run a rails console

```
bin/rails console
```

- get the `organisation` id for the delivery partner

```
organisation_id = Organisation.find_by(name: "NAME").id
```

- get the `Activity` id of the fund you are importing

```
gcrf_id = Activity.find_by(level: :fund, title: "Global Challenges Research Fund (GCRF)").id
```

or

```
newton_id = Activity.find_by(level: :fund, title: "Newton Fund").id
```

- create the report, financial quarter and year are read only so we use
  `update_all` to bypass those checks!

```
report = Report.new(fund_id: FUND_ID, organisation_id: organisation_id, state: :active, description: "Onboarding data import")
report.save!
Report.where(id: report.id).update_all(financial_quarter: 3, financial_year: 2020)
```

- Confirm `1` is returned, one record effected

- Confirm the report is now for Q3 2020:

```
report.reload
```

## Forecasts

Forecasts are kept in the main activity file along with the activity data.

You will have to extract the forecast columns into a separate file using a
script we have for this purpose.

We only import forecast data:

For newton:

- Level C

For GCRF:

- Level D

Do not import forecasts for level B for Newton data and level C for GCRF data as they are simply the sum of the
child forecasts.

## Prep forecast data

- run the script passing in the level, input file name and output file name
  constructor:

```
ruby script/convert_import.rb --level C --input /path/to/level/file.csv --output /path/to/level/out
```

The output will be two files:

- forecast data file `out_forecasts.csv`
- actual spend data file `out_transactions.csv`

Note how the output path is used to construct the name of the two output files.

The forecast data must start at the next financial quarter after the report we
created earlier, so the first column must be `FC 2020/21 FY Q4`, if the dataset
contains anything earlier, delete those columns.

- if any changes were made to the csv, make sure to save it as UTF-8 csv

## Import forecast data in prod

- copy the file over to prod

````
cat FILENAME.csv | cf ssh beis-roda-prod -c "cat > FILENAME.csv"
````

- connect to production:

```
cf login
cf ssh beis-roda-prod
```

- run the import

```
script/import_forecasts.rb  -f FUND NAME -o ORGANISATION NAME -q 3 -y 2020 -i FILENAME.csv
```

FUND NAME and ORGANISATION NAME are the strings used for
`Activity.roda_identifier` and
`Organisation.name` e.g. "NF" and "Academy of Medical Science".

## Actual spend

We only import actual data:

For Newton:

- Level C

For GCRF:

- Level D

We have to use the front end to run the actual spend import. You will need a
login to production and that account will need to belong to the correct
`Organisation` for the import.

The import will fail if you do not have the correct `Organisation` so we have
protection.

### Prep actual spend data

- the actual data is provided as a column for each financial quarter, however
  the import expects the following columns:

  - RODA ID
  - financial quarter
  - financial year
  - value

You already have the prepared file from the script run earlier.

## Import actual spend data into production

- setup your user account to belong to the correct `Organisation` i.e. the Delivery Partner
- connect to prod:

```
cf login
cf ssh beis-roda-prod
```

- run a rails console

```
bin/rails console
```

- locate your account

```
me = User.find_by(email: YOUREMAIL)
```
- locate the organisation id you want

```
Organisation.all.pluck(:name, :id)
```

- update your user

```
me.update(organisation_id: ORGANISATION_ID)
```

- run the import

- sign in to prod https://www.report-official-development-assistance.service.gov.uk
- go to reports
- go to the report for the fund you are importing actual spend for
- click on upload actuals
- provide the file and run the import


## Import completed
- zip the csv file used and attach to the Trello card
- move the Trello card to 'ready for review'
- let the team know in Slack that the import is complete:

:dolphin: Onboarding data complete for <DP NAME> <FUND NAME> :dolphin:
