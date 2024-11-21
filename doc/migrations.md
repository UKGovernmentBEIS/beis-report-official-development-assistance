# Migrations

### Schema

We use conventional Rails migrations to make changes to the schema. This
includes setting or changing relevant data.

Schema migrations are applied automatically on deployment via the docker-entrypoint.sh.

### Data / One-off tasks

When running a live service sometimes you're required to change existing data in
some way.

Currently, we don't have access to the live application console, so we're
handling data migrations the same way as conventional Rails migrations.
