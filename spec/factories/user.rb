FactoryBot.define do
  factory :delivery_partner, class: "User" do
    identifier { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    role { :delivery_partner }

    organisation

    factory :administrator do
      role { :administrator }
    end

    factory :fund_manager do
      role { :fund_manager }
    end
  end
end
