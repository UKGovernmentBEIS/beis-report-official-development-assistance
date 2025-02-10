FactoryBot.define do
  factory :actual, class: "Actual" do
    description { Faker::Lorem.paragraph }
    transaction_type { "1" }
    financial_quarter { FinancialQuarter.for_date(Date.current).quarter }
    financial_year { FinancialQuarter.for_date(Date.current).financial_year.start_year }
    value { BigDecimal("110.01") }
    disbursement_channel { "1" }
    currency { "gbp" }
    ingested { false }

    # Government organisation
    providing_organisation_name { "Department for Business, Energy & Industrial Strategy" }
    providing_organisation_reference { Organisation::SERVICE_OWNER_IATI_REFERENCE }
    providing_organisation_type { "10" }
    # Private organisation
    receiving_organisation_name { Faker::Company.name }
    receiving_organisation_reference { "GB-COH-{#{Faker::Number.number(digits: 6)}}" }
    receiving_organisation_type { "70" }

    association :parent_activity, factory: :project_activity
    association :report

    trait :with_comment do
      after(:create) do |actual, _evaluator|
        create(:comment, commentable: actual, report: actual.report)
        actual.reload
      end
    end

    trait :without_receiving_organisation do
      receiving_organisation_name { nil }
      receiving_organisation_reference { nil }
      receiving_organisation_type { nil }
    end

    trait :with_comment do
      after(:create) do |actual, _evaluator|
        create(:comment, commentable: actual, report: actual.report)
        actual.reload
      end
    end
  end
end
