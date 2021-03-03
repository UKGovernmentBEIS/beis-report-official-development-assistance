FactoryBot.define do
  factory :transfer do
    association :source, factory: :activity
    association :destination, factory: :activity

    financial_quarter { 1 }
    financial_year { Date.today.year }
    value { BigDecimal("110.01") }
  end
end
