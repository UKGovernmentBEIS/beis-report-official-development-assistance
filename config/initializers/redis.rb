require "connection_pool"

REDIS = if Rails.env.test?
  Redis::Namespace.new(:test, redis: MockRedis.new)
else
  ConnectionPool.new(size: 5, timeout: 5) do
    Redis::Namespace.new(
      :roda,
      redis: Redis.new(url: ENV["REDIS_URL"])
    )
  end
end
