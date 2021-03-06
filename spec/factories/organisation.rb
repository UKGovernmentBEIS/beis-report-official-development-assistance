FactoryBot.define do
  factory :organisation do
    sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
    beis_organisation_reference { Faker::Alphanumeric.alpha(number: 10).upcase! }
    iati_reference { "GB-GOV-#{Faker::Alphanumeric.alpha(number: 5).upcase!}" }
    organisation_type { "10" }
    default_currency { "GBP" }
    language_code { "en" }

    factory :delivery_partner_organisation do
      service_owner { false }

      trait :non_government do
        organisation_type { "22" }
      end
    end

    factory :beis_organisation do
      name { "Department for Business, Energy and Industrial Strategy" }
      iati_reference { "GB-GOV-13" }
      service_owner { true }
      initialize_with do
        Organisation.find_or_create_by(
          name: name,
          iati_reference: iati_reference,
          service_owner: service_owner
        )
      end
    end
  end
end
