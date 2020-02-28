redis_url = ENV.fetch("REDIS_URL", nil)
return if redis_url.nil?

redis_uri = URI(redis_url)
Rails.application.config.session_store :redis_store,
  servers: {
    host: redis_uri.host,
    port: redis_uri.port,
    db: 1,
    namespace: "roda:session",
  },
  expire_after: 12.hours
