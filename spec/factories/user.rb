FactoryBot.define do
  factory :user do
    identifier { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
  end
end
