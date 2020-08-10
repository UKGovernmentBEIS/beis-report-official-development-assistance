FactoryBot.define do
  factory :transaction do
    description { Faker::Lorem.paragraph }
    transaction_type { "1" }
    date { Date.today }
    value { BigDecimal("110.01") }
    disbursement_channel { "1" }
    currency { "gbp" }
    ingested { false }

    # Government organisation
    providing_organisation_name { "Department for Business, Energy & Industrial Strategy" }
    providing_organisation_reference { "GB-GOV-13" }
    providing_organisation_type { "10" }
    # Private organisation
    receiving_organisation_name { Faker::Company.name }
    receiving_organisation_reference { "GB-COH-{#{Faker::Number.number(digits: 6)}}" }
    receiving_organisation_type { "70" }

    association :parent_activity, factory: :activity
    association :submission
  end
end
