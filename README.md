[![Build Status](https://travis-ci.org/UKGovernmentBEIS/beis-report-official-development-assistance.svg?branch=develop)](https://travis-ci.org/UKGovernmentBEIS/beis-report-official-development-assistance)
[![Coverage Status](https://coveralls.io/repos/github/UKGovernmentBEIS/beis-report-official-development-assistance/badge.svg?branch=develop)](https://coveralls.io/github/UKGovernmentBEIS/beis-report-official-development-assistance?branch=develop)

# Report Official Development Assistance (RODA)

This service enables the Department for Business, Energy and Industrial Strategy (BEIS) and their delivery partners to collect and report information on the spending of Official Development Assistance (ODA).

## Getting started

1. copy `/.env.example` into `/.env.development.local`.

      Our intention is that the example should include enough to get the application started quickly. If this is not the case, please ask another developer for a copy of their `/.env.development.local` file.
1. set up the local database

      ```bash
      bundle exec rake db:setup
      ```

1. get the required GOVUK assets with NPM

      ```bash
      npm install
      ```

1. start Redis ([install guide](https://medium.com/@petehouston/install-and-config-redis-on-mac-os-x-via-homebrew-eb8df9a4f298))

      ```bash
      redis-server /usr/local/etc/redis.conf
      ```

1. start Sidekiq

      ```bash
      bundle exec sidekiq -C config/sidekiq.yml
      ```

1. start Rails

      ```bash
      bundle exec rails server
      ```

1. log in using the generic development user roda@dxw.com. Find the credentials in the team 1Password vault.

## Running the tests

To run all the tests, and linters we use `rake`:

```
bundle exec rake
```

Under the hood this is using RSpec so normal commands can be used:

```
bundle exec rspec spec
```

### Initial set up

```
createuser --super test
RAILS_ENV=test rake db:setup
```

## Architecture decision records

We use ADRs to document architectural decisions that we make. They can be found in doc/architecture/decisions and contributed to with the [adr-tools](https://github.com/npryce/adr-tools).

## Managing environment variables

We use [Dotenv](https://github.com/bkeepers/dotenv) to manage our environment variables locally.

The repository will include safe defaults for development in `/.env.example` and for test in `/.env.test`. We use 'example' instead of 'development' (from the Dotenv docs) to be consistent with current dxw conventions and to make it more explicit that these values are not to be committed.

To manage sensitive environment variables:

1. Add the new key and safe default value to the `/.env.example` file eg. `ROLLBAR_TOKEN=ROLLBAR_TOKEN`
2. Add the new key and real value to your local `/.env.development.local` file, which should never be checked into Git. This file will look something like `ROLLBAR_TOKEN=123456789`

## Release process

Releases are documented in the [CHANGELOG](CHANGELOG.md) following the [Keep a changelog](https://keepachangelog.com/en/1.0.0/) format.

When a new release is deployed to production (process TBC), a new second-level heading should be created in CHANGELOG.md with the release number and details of what has changed in this release.

The heading should link to a Github URL at the bottom of the file, which shows the differences between the current release and the previous one. For example:

```
## [release-1]
- A change
- Another change

[release-1]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-0...release-1
```

## Access

### Staging

The app is currently hosted on Heroku: [https://beis-roda-staging.herokuapp.com/](https://beis-roda-staging.herokuapp.com/)

The `develop` branch is deployed to staging after a successful build via Travis CI.

### Production

TBC

## Source

This repository was bootstrapped from [dxw's `rails-template`](https://github.com/dxw/rails-template).
