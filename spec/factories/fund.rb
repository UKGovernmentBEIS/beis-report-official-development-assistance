FactoryBot.define do
  factory :fund do
    name { Faker::Company.name }
    association :organisation, factory: :organisation
  end
end
