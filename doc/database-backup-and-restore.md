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
   cf services # to get the POSTGRES_SERVICE_NAME of postgres
   cf conduit POSTGRES_SERVICE_NAME -- pg_dump --file PROD_DATA_FILE_NAME.sql
   ```
1. Create a backup of the database we are about to overwrite and keep this as a local file
   ```
   cf target -s staging
   cf services # to get the POSTGRES_SERVICE_NAME
   cf conduit POSTGRES_SERVICE_NAME -- pg_dump --file STAGING_DATA_FILE_NAME.sql
   ```
1. Databases are linked to the app and worker service so we must find and unlink them
   ```
   cf unbind-service beis-roda-staging POSTGRES_SERVICE_NAME
   cf unbind-service beis-roda-staging-worker POSTGRES_SERVICE_NAME
   ```
1. Destroy the existing database (this may take 10 minutes)
   ```
   cf delete-service POSTGRES_SERVICE_NAME
   ```
1. Use Terraform to recreate it (this may take 10-20 minutes)
   ```
   terraform apply --var-file=staging.tfvars
   ```
1. Find the new database name
   ```
   cf conduit POSTGRES_SERVICE_NAME -- psql
   \l
   (It will start with "rdsbroker_")
   ```
1. Copy production data into the fresh database
   ```
   cf conduit POSTGRES_SERVICE_NAME -- psql -d NEW_DATABASE_NAME < ../PROD_DATA_FILE_NAME.sql
   ```
1. Seed the environment with organisations and users using the appropriate seed files
   ```
   load File.join(Rails.root, "db", "seeds", "organisations.rb")
   load File.join(Rails.root, "db", "seeds", "pentest_users.rb")
   ```

### PaaS to local

In this example we will overwrite our local development database with the
contents of the production database and add the local users so we can sign in to
the application.

---

### Prerequisites

- Cloud Foundry (`cf`) tool installed
- Credentials for the BEIS Government Platform as a Service (GPaaS) account
- [GPaaS Conduit plugin installed](#installing-the-cf-conduit-plugin)

1. Login and select the production space:
   ```
   cf login
   ```
1. List the backing services and note the name of the postgres service, this
   should be `beis-roda-prod-postgres` but we should confirm:
   ```
   cf services
   ```
1. Create a new backup of production data locally using cf conduit:
   ```
   cf conduit POSTGRES_SERVICE_NAME -- pg_dump --file PROD_DATA_FILE_NAME.sql --no-acl --no-owner
   ```
1. Destroy the existing local database in postgres and create a new empty one:
   ```
   psql -d postgres
     > DROP DATABASE "roda-development";
     > CREATE DATABASE "roda-development";
     > \q
   ```
1. Add production data to the new local database
   ```
   psql -d roda-development < PROD_DATA_FILE_NAME.sql
   ```
1. Add the local development users to the data we just imported using
   the Rails console, so that we can login to the application locally:
   ```
   bundle exec rails console
   ```
   ```
   load File.join(Rails.root, "db", "seeds", "development_users.rb")
   ```

## Installing the CF Conduit plugin

[CF Conduit is a Cloud Foundry
plugin](https://github.com/alphagov/paas-cf-conduit) written by the GPaaS team
to support the GPaaS service.

To install the plugin:

```
cf install-plugin conduit
```

This step warns of untrusted packages, we trust that the author is the
Government Digital Service.
