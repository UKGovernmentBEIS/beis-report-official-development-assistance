FactoryBot.define do
  factory :administrator, class: "User" do
    identifier { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    active { true }

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
  end
end
