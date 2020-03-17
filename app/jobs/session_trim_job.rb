# Periodically trim old and expired sessions
# https://github.com/rails/activerecord-session_store
class SessionTrimJob
  include Sidekiq::Worker
  def perform
    Rake::Task["db:sessions:trim"].invoke
  end
end
