FactoryBot.define do
  sequence(:iati_reference) { |n| "GB-GOV-#{n}" }

  factory :organisation do
    name { Faker::Company.name }
    iati_reference
    organisation_type { "10" }
    default_currency { "GBP" }
    language_code { "en" }
  end
end
