FactoryBot.define do
  factory :user do
    identifier { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    role { :delivery_partner }

    factory :administrator do
      role { :administrator }
    end

    factory :delivery_partner do
      role { :delivery_partner }
    end
  end
end
