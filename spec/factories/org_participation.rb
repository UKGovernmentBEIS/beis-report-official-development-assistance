FactoryBot.define do
  factory :org_participation do
    association :organisation, factory: :unique_implementing_organisation
    association :activity, factory: :programme_activity
    role { "Implementing" }
  end
end
