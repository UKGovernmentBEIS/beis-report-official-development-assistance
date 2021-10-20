FactoryBot.define do
  factory :report do
    description { Faker::Lorem.paragraph }
    state { :active }
    deadline { 1.year.from_now }

    association :fund, factory: :fund_activity
    association :organisation, factory: :delivery_partner_organisation

    trait :approved do
      state { :approved }
      deadline { 1.day.from_now }
    end
  end
end
