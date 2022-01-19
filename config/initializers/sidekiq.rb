redis_url = ENV["REDIS_URL"]

options = {
  concurrency: Integer(ENV.fetch("RAILS_MAX_THREADS", 5))
}

Sidekiq.configure_server do |config|
  config.logger.level = Logger::WARN if Rails.env.production?
  config.options.merge!(options)
  config.redis = {
    url: redis_url,
    size: config.options[:concurrency] + 5
  }
end

Sidekiq.configure_client do |config|
  config.options.merge!(options)
  config.redis = {
    url: redis_url,
    size: config.options[:concurrency] + 5
  }
end
