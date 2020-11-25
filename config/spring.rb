# frozen_string_literal: true

Spring.watch(
  ".ruby-version",
  ".rbenv-vars",
  "tmp/restart.txt",
  "tmp/caching-dev.txt"
)

Spring.after_fork do
  if Rails.env.test?
    RSpec.configure do |config|
      config.seed = srand % 0xFFFF unless ARGV.any? { |arg| arg =~ /seed/ }
    end
  end
end
