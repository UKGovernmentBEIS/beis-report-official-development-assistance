require "connection_pool"

REDIS = ConnectionPool.new(size: 5, timeout: 5) {
  Redis::Namespace.new(
    :roda,
    redis: Redis.new(url: ENV["REDIS_URL"])
  )
}
