FactoryBot.define do
  factory :organisation do
    name { Faker::Company.name }
    iati_reference { "GB-GOV-#{Faker::Alphanumeric.alpha(number: 5).upcase!}" }
    organisation_type { "10" }
    default_currency { "GBP" }
    language_code { "en" }

    factory :delivery_partner_organisation do
      service_owner { false }
    end

    factory :beis_organisation do
      name { "Department for Business, Energy and Industrial Strategy" }
      service_owner { true }
    end
  end
end
