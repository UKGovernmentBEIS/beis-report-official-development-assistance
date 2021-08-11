FactoryBot.define do
  factory :refund do
    association :parent_activity, factory: :project_activity
    association :report

    financial_quarter { FinancialQuarter.for_date(Date.today).quarter }
    financial_year { FinancialQuarter.for_date(Date.today).financial_year.start_year }
    value { BigDecimal("110.01") }
    comment { Faker::Lorem.paragraph }
  end
end
