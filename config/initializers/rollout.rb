require "redis"

ROLLOUT = Rollout.new(Redis.current)

ROLLOUT.define_group(:beis_users) do |user|
  user.service_owner?
end

ROLLOUT.define_group(:partner_organisation_users) do |user|
  user.partner_organisation?
end

Rollout::UI.configure do
  instance { ROLLOUT }
end

def hide_ispf_for_group?(user_group)
  ROLLOUT.get(:ispf_fund_in_stealth_mode).groups.include?(user_group)
end

def hide_ispf_for_user?(user)
  ROLLOUT.active?(:ispf_fund_in_stealth_mode, user)
end
