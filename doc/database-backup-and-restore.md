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

You'll need to have credentials for the BEIS GPaaS account. ([GOV.UK
Platform-as-a-Service](https://www.cloud.service.gov.uk/))

#### Installing Cloud Foundry

A download link for the Cloud Foundry command line tool appears once you are
logged into GPaaS at https://www.cloud.service.gov.uk/. After downloading it,
open it in Finder rather than double-clicking it directly, because there may
be a warning that it is infrequently downloaded that cannot be bypassed when
opening it from the browser (a second, grey, button will appear to allow
you to install it anyway.)

#### Installing the CF Conduit plugin

[CF Conduit is a Cloud Foundry
plugin](https://github.com/alphagov/paas-cf-conduit) written by the GPaaS team
to support the GPaaS service.

To install the plugin:

```
cf install-plugin conduit
```

This step warns of untrusted packages, we trust that the author is the
Government Digital Service.

#### Download the database

To overwrite your local development environment with the contents of a
live environment, and seed the database with fake local users, you can
run this command:

```bash
script/db-restore ENVIRONMENT
```

(Where `ENVIRONMENT` is one of `pentest`, `prod` or `staging` - default is
`staging`, but `prod` may be more appropriate.
