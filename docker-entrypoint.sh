#!/bin/bash
set -e

echo "Starting docker entrypoint…"

setup_database()
{
  echo "Preparing database…"
  bundle exec rake db:prepare
  echo "Finished database setup."
}

run_data_migrations()
{
  if [ "$DATA_MIGRATE" == "false" ];
  then
    echo "Skipping data migrations"
  else
    echo "Running data migrations…"
    bundle exec rake data:migrate
    echo "Finished running data migrations."
  fi
}

if [ -z ${DATABASE_URL+x} ]; then echo "Skipping database setup"; else setup_database; fi
if [ "$RAILS_ENV" == "production" ]; then run_data_migrations; else echo "Not running data migrations, not in production"; fi

echo "Finished docker entrypoint."
exec "$@"
