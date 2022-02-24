FactoryBot.define do
  factory :administrator, class: "User" do
    identifier { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    active { true }
    password { SecureRandom.uuid }
    mobile_number { Faker::PhoneNumber.phone_number }
    mobile_number_confirmed_at { 1.day.ago }

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

    trait :no_mobile_number do
      mobile_number              { nil }
      mobile_number_confirmed_at { nil }
    end
  end
end
