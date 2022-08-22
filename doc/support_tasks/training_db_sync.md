# Update the data on the "training" environment

See `script/trainingdb_sync.rb`

This script is designed to update the 'training' environment
with a copy of the production data ('prod').

User credentials are scrubbed, requiring users to reset their
passwords after each 'sync'.

## HOW TO USE IT
It can be run from a developer or ops person's laptop
provided the user has:

- a GPaaS (https://docs.cloud.service.gov.uk) account for BEIS RODA
- the Cloudfoundry tools installed
  (https://docs.cloud.service.gov.uk/get_started.html#set-up-the-cloud-foundry-command-line)
- installed the Conduit plugin for Cloudfoundry/GPaaS
  (https://docs.cloud.service.gov.uk/guidance.html#using-the-conduit-plugin)

Environment variables expected:

- `GPAAS_CF_USER`
- `GPAAS_CF_PASSWORD`

Set these in your `.env` file or export to your shell
manually.

Run the script using the `bin/rails runner` command so that
the required libraries such as `Date`, `Open3` and
`FileUtils` are loaded:

`bin/rails runner script/training_db_sync.rb`

## WHAT IT DOES
See the `TrainingDbSync#call` method for a description of the
script's steps:

- print_plan
- capture_data_from_source
- copy_data_to_destination
- load_source_data_to_destination
- force_password_reset_for_users
- remove_temp_files

Please note a couple of details of the data dump and
data load steps which were found to work with the GPaaS
setup:

- the data is dumped from `prod` using `pg-dump --clean`: this
includes instructions in the dump file for db objects to be
dropped before importing new items

- the data dump is applied to `training` using
`psql < dumpfile` rather than using `pg_restore`.

## FUTURE PLANS
It is our intention to develop this script in the future to
perform the data sync automatically on a scheduled basis.
