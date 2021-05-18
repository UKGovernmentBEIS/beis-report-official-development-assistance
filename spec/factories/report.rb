FactoryBot.define do
  factory :report do
    description { Faker::Lorem.paragraph }
    state { :inactive }

    association :fund, factory: :fund_activity
    association :organisation, factory: :delivery_partner_organisation

    trait :active do
      state { :active }
      deadline { 1.year.from_now }
    end

    trait :approved do
      state { :approved }
      deadline { 1.day.from_now }
    end
  end
end
