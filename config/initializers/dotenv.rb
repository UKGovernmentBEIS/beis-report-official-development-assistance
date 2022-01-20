# Require environment variables on initialisation
# https://github.com/bkeepers/dotenv#required-keys
if defined?(Dotenv)
  Dotenv.require_keys(
    "DOMAIN",
    "DATABASE_URL",
    "REDIS_URL",
    "SECRET_KEY_BASE",
    "AUTH0_CLIENT_ID",
    "AUTH0_CLIENT_SECRET",
    "AUTH0_DOMAIN"
  )
end
