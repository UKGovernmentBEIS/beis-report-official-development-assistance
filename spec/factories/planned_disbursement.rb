FactoryBot.define do
  factory :planned_disbursement do
    planned_disbursement_type { "1" }
    currency { "gbp" }
    value { BigDecimal("100000.00") }
    association :parent_activity, factory: :project_activity
    providing_organisation_name { "Delivery partner" }
    providing_organisation_type { "10" }
    providing_organisation_reference { "GB-COH-1233442" }
    receiving_organisation_name { Faker::Company.name }
    receiving_organisation_reference { "GB-COH-{#{Faker::Number.number(digits: 6)}}" }
    receiving_organisation_type { "70" }
    financial_quarter { "2" }
    financial_year { "2020" }
    period_start_date { "2020-07-01".to_date }
    period_end_date { period_start_date.end_of_quarter }

    association :report
  end
end
