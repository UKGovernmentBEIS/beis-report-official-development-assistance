FactoryBot.define do
  factory :budget do
    budget_type { "1" }
    status { "1" }
    period_start_date { Date.today }
    period_end_date { Date.tomorrow }
    value { BigDecimal("110.01") }
    currency { "gbp" }
    ingested { false }
    funding_type { 1 }
    association :parent_activity, factory: :activity
    association :report, factory: :report
  end
end
