FactoryBot.define do
  factory :adjustment do
    transaction_type { "1" }
    disbursement_channel { "1" }
    currency { "gbp" }
    ingested { false }
    financial_quarter { 1 }
    financial_year { 2020 }
    value { BigDecimal("110.01") }

    association :parent_activity, factory: :project_activity
    report { association :report, financial_quarter: financial_quarter, financial_year: financial_year + 1 }

    receiving_organisation_name { nil }
    receiving_organisation_reference { nil }
    receiving_organisation_type { nil }

    after(:create) do |adjustment, _evaluator|
      create(:comment, commentable: adjustment, report: adjustment.report)
      adjustment.reload
    end

    trait :refund do
      after(:create) do |adjustment, _evaluator|
        create(:adjustment_detail, adjustment: adjustment, adjustment_type: "Refund")
        adjustment.reload
      end
    end

    trait :actual do
      after(:create) do |adjustment, _evaluator|
        create(:adjustment_detail, adjustment: adjustment, adjustment_type: "Actual")
        adjustment.reload
      end
    end
  end
end
