FactoryBot.define do
  factory :organisation do
    name { Faker::Company.name }
    organisation_type { "10" }
    default_currency { "gbp" }
    language_code { "en" }
  end
end
