FactoryBot.define do
  factory :implementing_organisation do
    name { Faker::Company.name }
    reference
    organisation_type { "10" }
  end
end
