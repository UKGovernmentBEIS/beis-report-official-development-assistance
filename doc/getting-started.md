# Getting started

First, run the setup script. This installs the required system (assuming you're
using OSX and Homebrew), frontend and Ruby dependencies, as well as setting up
the test and development databases.

```bash
script/setup
```

Once setup has been completed, you can start the server with

```bash
script/server
```

and the tests should pass

```bash
script/test
```

## Running backing services with Docker compose

If you prefer not to install the backing services (Postgres and Redis) with
Homebrew via the scripts above, run them in the background with Docker and
then use standard rails commands to interact with the application (you will need
Docker installed on your device):

```
docker compose -f backing-services-docker-compose.yml up -d
```

To stop the backing services:

```
docker compose -f backing-services-docker-compose.yml down
```
