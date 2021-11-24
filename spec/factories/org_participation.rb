FactoryBot.define do
  factory :org_participation do
    association :organisation
    association :activity, factory: :programme_activity
    role { :implementing }
  end
end
