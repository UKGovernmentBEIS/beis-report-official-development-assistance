FactoryBot.define do
  sequence(:reference) { |n| "organisation-#{n}" }

  factory :implementing_organisation do
    name { Faker::Company.name }
    reference
    organisation_type { "10" }

    association :activity, factory: :project_activity
  end
end
