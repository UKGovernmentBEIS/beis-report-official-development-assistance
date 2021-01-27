FactoryBot.define do
  factory :transfer do
    association :source, factory: :activity
    association :destination, factory: :activity

    date { Date.today }
    value { BigDecimal("110.01") }
  end
end
