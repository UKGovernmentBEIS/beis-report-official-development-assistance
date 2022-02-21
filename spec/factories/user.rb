FactoryBot.define do
  factory :administrator, class: "User" do
    identifier { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    active { true }
    password { SecureRandom.uuid }
    mobile_phone_number { Faker::PhoneNumber.phone_number }

    organisation factory: :beis_organisation

    factory :beis_user do
      organisation factory: :beis_organisation
    end

    factory :delivery_partner_user do
      organisation factory: :delivery_partner_organisation
    end

    factory :inactive_user do
      active { false }
    end

    trait :new_user do
      password { nil }
    end

    trait :mfa_enabled do
      otp_required_for_login { true }
    end
  end
end
