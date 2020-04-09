#!/bin/bash
set -e

echo "Starting docker entrypoint…"

setup_database()
{
  echo "Running data migrations…"
  bundle exec rake data:migrate
  echo "Finished running data migrations."

  echo "Preparing database…"
  bundle exec rake db:prepare
  echo "Finished database setup."
}

if [ -z ${DATABASE_URL+x} ]; then echo "Skipping database setup"; else setup_database; fi

echo "Finished docker entrypoint."
exec "$@"
