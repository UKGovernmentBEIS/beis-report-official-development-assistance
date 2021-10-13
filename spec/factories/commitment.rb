FactoryBot.define do
  factory :commitment do
    association :activity, factory: :programme_activity
    value { BigDecimal("120.45") }
    financial_quarter { 1 }
    financial_year { 2021 }
  end
end
