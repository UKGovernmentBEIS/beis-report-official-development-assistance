redis_url = ENV.fetch("REDIS_URL", nil)
if redis_url.nil?
  # If REDIS_URL is unexpectedly unavailable Rails will use the default
  # cookie_store. We declare this explicity so the fallback is clear.
  Rails.application.config.session_store :cookie_store,
    key: "_roda_session",
    expire_after: 12.hours
  return
end

redis_uri = URI(redis_url)
redis_store_params = {
  servers: {
    host: redis_uri.host,
    port: redis_uri.port,
    db: 1,
    namespace: "roda:session",
  },
  key: "_roda_session",
  expire_after: 12.hours,
  threadsafe: true,
}
redis_store_params[:secure] = true if Rails.env.production?

Rails.application.config.session_store :redis_store, redis_store_params
