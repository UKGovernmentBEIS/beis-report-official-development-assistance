#!/bin/bash
set -e

echo "Starting docker entrypoint…"

setup_database()
{
  echo "Preparing database…"
  rake db:prepare
  echo "Finished database setup."
}

if [ -z ${DATABASE_URL+x} ]; then echo "Skipping database setup"; else setup_database; fi

echo "Finished docker entrypoint."
exec "$@"
