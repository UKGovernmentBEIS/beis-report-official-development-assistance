FactoryBot.define do
  factory :matched_effort do
    funding_type { "in_kind" }
    category { "staff_time" }
    committed_amount { 100.00 }
    currency { "GBP" }
    exchange_rate { 1.00 }
    date_of_exchange_rate { Date.today }
    notes { Faker::Lorem.paragraph }

    association :activity, factory: :project_activity
    association :organisation, factory: :matched_effort_provider
  end
end
