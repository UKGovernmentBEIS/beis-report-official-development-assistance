FactoryBot.define do
  factory :refund do
    association :parent_activity, factory: :project_activity
    association :report

    financial_quarter { FinancialQuarter.for_date(Date.today).quarter }
    financial_year { FinancialQuarter.for_date(Date.today).financial_year.start_year }
    value { BigDecimal("110.01") }

    after(:create) do |refund, _evaluator|
      create(:flexible_comment, commentable: refund)
      refund.reload
    end
  end
end
