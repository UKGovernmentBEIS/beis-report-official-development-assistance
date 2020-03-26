# Database backup and restore

Postgres instances are hosted within GPaaS and exist as backing services.
GPaaS has a number of [options available to help with backing up and restoring the database](https://docs.cloud.service.gov.uk/deploying_services/postgresql/#postgresql-maintenance-amp-backups).

## Restore from an automated backup

https://docs.cloud.service.gov.uk/deploying_services/postgresql/#restoring-a-postgresql-service-snapshot

## Manual backup and restore

---

### [PaaS to PaaS (this includes space to space)](https://docs.cloud.service.gov.uk/deploying_services/postgresql/#paas-to-paas)

This process has been used to take real production data and add it to non-production environments. This is useful to test against realistic data sets.

For this example we will add production data to the staging environment.

You will need to be a user of the services GPaaS account. You're OK if you can sign into https://cloud.service.gov.uk, see the RODA service and the space you're intending to work on, eg `prod` and `staging`. Any member of the development team should be able to invite you.

1. Sign into the platform from your machine
    ```
    cf login
    ```
1. Install the local [Conduit plugin](https://github.com/alphagov/paas-cf-conduit) for Cloudfoundry. This step warns of untrusted packages. We trust that the author is the Government Digital Service and confirm
    ```
    cf install-plugin conduit
    ```
1. Create a new backup of production
    ```
    cf target -s prod
    cf services # to get the SERVICE_NAME of postgres
    cf conduit SERVICE_NAME -- pg_dump --file PROD_DATA_FILE_NAME.sql
    ```
1. Create a backup of the database we are about to overwrite and keep this as a local file
    ```
    cf target -s staging
    cf services # to get the SERVICE_NAME
    cf conduit SERVICE_NAME -- pg_dump --file STAGING_DATA_FILE_NAME.sql
    ```
1. Find the Database role name from the database dump. It should be of the form: `rdsbroker_<uuid>_manager`
    ```
    grep -n rdsbroker PROD_DATA_FILE_NAME.sql
    ```
1. Connect to the target database with a PostgreSQL prompt
    ```
    cf target -s staging
    cf services # to get the SERVICE_NAME for the destination postgres
    cf conduit SERVICE_NAME -- psql
    ```
1. Wipe the target staging database. Inserting the role name from the PROD_DATA_FILE_NAME.sql
    ```
    DROP DATABASE "roda-staging";
    CREATE DATABASE "roda-staging";
    CREATE ROLE "rdsbroker_<uuid>_manager" WITH SUPERUSER CREATEDB CREATEROLE;
    ```
1. Add data to the target staging database
    ```
    cf target -s staging
    cf services # to get the DESTINATION_SERVICE_NAME for the destination postgres
    cf conduit DESTINATION_SERVICE_NAME -- psql -d roda-staging < PROD_DATA_FILE_NAME.sql
    ```
1. Ask Rake to prepare the database [using a rails console](/doc/console-access.md)
    ```
    rake db:prepare
    ```
1. Seed the database with generic roda@dxw.com and roda+dp@dxw.com users to allow us to sign in. [Use a rails console](/doc/console-access.md) to add the generic users by copying the contents of the `db/seeds/staging_users.rb`
1. Sign into the service to verify data is present

### PaaS to local

In this example we will overwrite our local development database with the contents of the production database.

---

1. Create a new backup of production
    ```
    cf install-plugin conduit
    cf target -s prod
    cf services # to get the SERVICE_NAME of postgres
    cf conduit SERVICE_NAME -- pg_dump --file PROD_DATA_FILE_NAME.sql
    ```
1. Find the Database role name from the database dump. It should be of the form: `rdsbroker_<uuid>_manager`
    ```
    grep -n rdsbroker PROD_DATA_FILE_NAME.sql
    ```
1. Use the Postgres binary to wipe and prepare the local database (if you've done this process before you'll get a warning that this role already exists)
    ```
    psql
      > DROP DATABASE "roda-development";
      > CREATE DATABASE "roda-development";
      > CREATE ROLE "rdsbroker_de78448a_1869_4e6c_9ffc_1256420e96f3_manager" WITH SUPERUSER CREATEDB CREATEROLE;
    ```
1. Add production data to the clean local database
    ```
    psql -d roda-development < PROD_DATA_FILE_NAME.sql
    ```
1. Prepare and seed the database
    ```
    rake db:prepare
    rake db:seed
    ```
1. Log in using generic development credentials

NB. As a product of restoring the production database, some postgres plugins will be added to your local schema along with a table called `spatial_ref_sys`. You can safely ignore/discard these changes to your schema. In the future and with more time we could look at ways to prevent this side effect.
