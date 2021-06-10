FactoryBot.define do
  factory :outgoing_transfer do
    association :source, factory: :project_activity
    association :destination, factory: :project_activity

    financial_quarter { 1 }
    financial_year { Date.today.year }
    value { BigDecimal("110.01") }
  end
end
