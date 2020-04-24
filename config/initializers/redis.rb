require "connection_pool"

if Rails.env.test?
  redis_namespace = :test
  redis_connection = MockRedis.new
else
  redis_namespace = :roda
  redis_connection = Redis.new(url: ENV["REDIS_URL"])
end

ConnectionPool.new(size: 5, timeout: 5) do
  Redis::Namespace.new(redis_namespace, redis: redis_connection)
end

# Check Redis is ready to accept connections
redis_connection.ping if ENV["REDIS_URL"]
