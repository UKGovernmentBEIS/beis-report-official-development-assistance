FactoryBot.define do
  factory :administrator, class: "User" do
    identifier { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    role { :administrator }

    organisation
  end
end
