FactoryBot.define do
  factory :planned_disbursement do
    planned_disbursement_type { "1" }
    period_start_date { Date.today + 1.year }
    currency { "gbp" }
    value { BigDecimal("100000.00") }
    association :parent_activity, factory: :project_activity
    providing_organisation_name { "Delivery partner" }
    providing_organisation_type { "10" }
    providing_organisation_reference { "GB-COH-1233442" }
    receiving_organisation_name { Faker::Company.name }
    receiving_organisation_reference { "GB-COH-{#{Faker::Number.number(digits: 6)}}" }
    receiving_organisation_type { "70" }
  end
end
