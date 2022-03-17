namespace :sessions do
  desc "delete all sessions from REDIS"
  task delete_all: :environment do
    # We needed to delete all active sessions when migrating from Auth0 / OmniAuth
    # to Devise to avoid "OmniAuth: name not found" error on unmarshalling Redis sessions
    # (aka deserialising)

    # Note: this gave the following deprecation warning:
    # Passing 'select' command to redis as is; administrative commands cannot be effectively namespaced
    # and should be called on the redis connection directly; passthrough has been deprecated and will be
    # removed in redis-namespace 2.0

    # Be surprised if this actually works in the future -- this one

    REDIS.with do |conn| # REDIS gives us the roda: namespace, see config/initializers/redis.rb
      conn.select(1) # select correct database -- hopefully there's only ever one.
      sessions = conn.keys("session:*")
      puts "deleting #{sessions.length} sessions"
      sessions.each do |session|
        puts "deleting #{session}"
        conn.del(session)
      end
    end
  end
end
