FactoryBot.define do
  factory :submission do
    description { Faker::Lorem.paragraph }
    state { :inactive }

    association :fund, factory: :fund_activity
    association :organisation
  end
end
