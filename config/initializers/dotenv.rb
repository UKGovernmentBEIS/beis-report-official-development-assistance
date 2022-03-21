# Require environment variables on initialisation
# https://github.com/bkeepers/dotenv#required-keys
if defined?(Dotenv)
  Dotenv.require_keys(
    "DOMAIN",
    "DATABASE_URL",
    "REDIS_URL",
    "SECRET_KEY_BASE"
  )
end
