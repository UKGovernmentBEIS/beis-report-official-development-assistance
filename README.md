# Report Overseas Development Assistance (RODA)

This service enables the Department for Business, Energy and Industrial Strategy (BEIS) and their delivery partners to collect and report information on the spending of Overseas Development Assistance (ODA).

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

1. start the server

  ```bash
  bundle exec rails server
  ```

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

## Running with Docker

The application can also be run with Docker. 

### Prerequisites

- [Docker](https://docs.docker.com/docker-for-mac)

Once you have installed Docker, set up your `.env` file:
 
`cp docker-compose.env.example docker-compose.env`

Run the application:

```bash
  docker-compose up
```

## Architecture decision records

We use ADRs to document architectural decisions that we make. They can be found in doc/architecture/decisions and contributed to with the [adr-tools](https://github.com/npryce/adr-tools).

## Managing environment variables

We use [Dotenv](https://github.com/bkeepers/dotenv) to manage our environment variables locally.

The repository will include safe defaults for development in `/.env.example` and for test in `/.env.test`. We use 'example' instead of 'development' (from the Dotenv docs) to be consistent with current dxw conventions and to make it more explicit that these values are not to be committed.

To manage sensitive environment variables:

1. Add the new key and safe default value to the `/.env.example` file eg. `ROLLBAR_TOKEN=ROLLBAR_TOKEN`
2. Add the new key and real value to your local `/.env.development.local` file, which should never be checked into Git. This file will look something like `ROLLBAR_TOKEN=123456789`

## Access

TODO: Where can people find the service and the different environments?

## Source

This repository was bootstrapped from [dxw's `rails-template`](https://github.com/dxw/rails-template).
