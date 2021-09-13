FactoryBot.define do
  factory :adjustment do
    transaction_type { "1" }
    disbursement_channel { "1" }
    currency { "gbp" }
    ingested { false }
    financial_quarter { FinancialQuarter.for_date(Date.today).quarter }
    financial_year { FinancialQuarter.for_date(Date.today).financial_year.start_year }
    value { BigDecimal("110.01") }

    association :parent_activity, factory: :project_activity
    association :report

    receiving_organisation_name { nil }
    receiving_organisation_reference { nil }
    receiving_organisation_type { nil }

    after(:create) do |adjustment, _evaluator|
      create(:flexible_comment, commentable: adjustment)
      adjustment.reload
    end
  end
end
