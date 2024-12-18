FactoryBot.define do
  factory :administrator, class: "User" do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    deactivated_at { nil }
    anonymised_at { nil }
    password { "Ab1!#{SecureRandom.uuid}" }
    mobile_number { Faker::PhoneNumber.phone_number }
    mobile_number_confirmed_at { 1.day.ago }
    otp_required_for_login { false }

    organisation factory: :beis_organisation

    factory :beis_user do
      organisation factory: :beis_organisation
    end

    factory :partner_organisation_user do
      organisation factory: :partner_organisation
    end

    factory :inactive_user do
      deactivated_at { Date.yesterday }
    end

    trait :new_user do
      password { nil }
    end

    trait :mfa_enabled do
      otp_required_for_login { true }
    end

    trait :no_mobile_number do
      mobile_number { nil }
      mobile_number_confirmed_at { nil }
    end
  end
end
