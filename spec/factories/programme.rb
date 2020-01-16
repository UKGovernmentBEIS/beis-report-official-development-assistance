FactoryBot.define do
  factory :programme do
    name { Faker::Company.name }
    association :organisation
    association :fund
  end
end
