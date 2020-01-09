FactoryBot.define do
  factory :user do
    identifier { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    role { :delivery_partner }

    factory :administrator do
      role { :administrator }
    end

    factory :fund_manager do
      role { :fund_manager }
    end
  end
end
