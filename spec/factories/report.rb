FactoryBot.define do
  factory :report do
    description { Faker::Lorem.paragraph }
    state { :inactive }

    association :fund, factory: :fund_activity
    association :organisation

    trait :active do
      state { :active }
      deadline { 1.year.from_now }
    end
  end
end
