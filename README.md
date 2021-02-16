[![Build Status](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/workflows/CI/badge.svg?branch=develop)](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/actions?query=branch%3Adevelop)
[![Coverage Status](https://coveralls.io/repos/github/UKGovernmentBEIS/beis-report-official-development-assistance/badge.svg?branch=develop)](https://coveralls.io/github/UKGovernmentBEIS/beis-report-official-development-assistance?branch=develop)

# Report Official Development Assistance (RODA)

This service enables the Department for Business, Energy and Industrial Strategy (BEIS) and their delivery partners to collect and report information on the spending of Official Development Assistance (ODA).

## Getting started

First, run the setup script. This installs the required system (assuming you're using OSX and Homebrew), frontend and Ruby dependencies, as well as setting up the test and development databases.

```bash
script/setup
```

Once setup has been completed, you can start the server with

```bash
script/server
```

## Running the tests

```bash
script/test
```

## Running backing services with Docker compose

If you prefer not to install the backing services (Postgres and Redis) with
Homebrew via the scripts above, run them in the background with Docker and
then use standard rails commands to interact with the application (you will need
Docker installed on your device):

````
docker-compose -f backing-services-docker-compose.yml up -d
````

To stop the backing services:

````
docker-compose -f backing-services-docker-compose.yml down
````

## Architecture decision records

We use ADRs to document architectural decisions that we make. They can be found in doc/architecture/decisions and contributed to with the [adr-tools](https://github.com/npryce/adr-tools).

## Managing environment variables

We use [Dotenv](https://github.com/bkeepers/dotenv) to manage our environment variables locally.

The repository will include safe defaults for development in `/.env.example` and for test in `/.env.test`. We use 'example' instead of 'development' (from the Dotenv docs) to be consistent with current dxw conventions and to make it more explicit that these values are not to be committed.

To manage sensitive environment variables:

1. Add the new key and safe default value to the `/.env.example` file eg. `ROLLBAR_TOKEN=ROLLBAR_TOKEN`
2. Add the new key and real value to your local `/.env.development.local` file, which should never be checked into Git. This file will look something like `ROLLBAR_TOKEN=123456789`

## Release process

[Our release process is documented locally](/doc/deployment-process.md).

## Migrations

### Schema

We use conventional Rails migrations to make changes to the schema. This includes setting or changing relevant data.

Schema migrations are applied automatically on deployment via the docker-entrypoint.sh.

### Data / One-off tasks

We use the [data-migrate](https://github.com/ilyakatz/data-migrate) gem to make changes to data that do not require schema changes.

This can be useful if we need to fix missing data fields or improve the quality of data. For example upcasing all values of a certain field at the same time as adding in validation for the same.

Data migrations are applied automatically on deployment via the docker-entrypoint.sh.

## Access

### Staging

The app is currently hosted on GPaaS: [https://beis-roda-staging.london.cloudapps.digital](https://beis-roda-staging.london.cloudapps.digital)

The `develop` branch is deployed to staging after a successful build via Travis CI.

### Production

The app is currently hosted on GPaaS: [https://beis-roda-prod.london.cloudapps.digital](https://beis-roda-prod.london.cloudapps.digital)

The `master` branch is deployed to production after a successful build via Travis CI.

## DNS

The DNS for the service is hosted and managed by [dxw](https://dxw.com) the
source for which is maintained in this private repo:

[https://github.com/dxw/beis-roda-dns](https://github.com/dxw/beis-roda-dns)



## Source

This repository was bootstrapped from [dxw's `rails-template`](https://github.com/dxw/rails-template).
