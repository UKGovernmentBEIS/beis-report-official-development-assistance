FactoryBot.define do
  sequence(:reference) { |n| "transaction-#{n}" }

  factory :transaction do
    reference
    description { Faker::Lorem.paragraph }
    transaction_type { "1" }
    date { Date.today }
    value { 110.01 }
    disbursement_channel { "1" }
    currency { "gbp" }
    association :provider, factory: :organisation
    association :receiver, factory: :organisation
  end
end
