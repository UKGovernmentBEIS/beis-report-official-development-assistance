FactoryBot.define do
  factory :budget do
    budget_type { 1 }
    financial_year { Date.current.next_year.year }
    value { BigDecimal("110.01") }
    currency { "gbp" }
    ingested { false }
    association :parent_activity, factory: :activity
    association :report, factory: :report
  end
end
