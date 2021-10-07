FactoryBot.define do
  factory :commitment do
    association :activity, factory: :programme_activity
    value { BigDecimal("120.45") }
  end
end
