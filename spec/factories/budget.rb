FactoryBot.define do
  factory :budget do
    budget_type { "original" }
    status { "indicative" }
    period_start_date { Date.today }
    period_end_date { Date.tomorrow }
    value { 110.01 }
    association :activity
  end
end
