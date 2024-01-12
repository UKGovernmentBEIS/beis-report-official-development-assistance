require "redis"

REDIS.with do |connection|
  connection.select(1)
  ROLLOUT = Rollout.new(connection)
end

ROLLOUT.define_group(:beis_users) do |user|
  user.service_owner?
end

ROLLOUT.define_group(:partner_organisation_users) do |user|
  user.partner_organisation?
end

Rollout::UI.configure do
  instance { ROLLOUT }
end
