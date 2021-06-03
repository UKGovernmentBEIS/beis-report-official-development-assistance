FactoryBot.define do
  factory :external_income do
    amount { 1100.00 }
    financial_quarter { FinancialQuarter.for_date(Date.today).quarter }
    financial_year { FinancialQuarter.for_date(Date.today).financial_year.start_year }
    oda_funding { true }

    association :activity, factory: :project_activity
    association :organisation, factory: :external_income_provider
  end
end
