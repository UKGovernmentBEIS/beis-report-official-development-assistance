require "redis"

ROLLOUT = Rollout.new(Redis.current)

ROLLOUT.define_group(:beis_users) do |user|
  user.service_owner?
end

ROLLOUT.define_group(:partner_organisation_users) do |user|
  user.partner_organisation?
end
