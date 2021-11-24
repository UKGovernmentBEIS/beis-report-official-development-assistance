FactoryBot.define do
  factory :__organisation do
    sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
    beis_organisation_reference { Faker::Alphanumeric.alpha(number: 5).upcase! }
    iati_reference { "GB-GOV-#{Faker::Alphanumeric.alpha(number: 5).upcase!}" }
    organisation_type { "10" }
    default_currency { "GBP" }
    language_code { "en" }

    factory :delivery_partner_organisation do
      role { "delivery_partner" }

      trait :non_government do
        organisation_type { "22" }
      end
    end

    factory :matched_effort_provider do
      role { "matched_effort_provider" }
    end

    factory :external_income_provider do
      role { "external_income_provider" }
    end

    factory :participating_organisation do
      name { "UKRI" }
      role { nil }
      alternate_names { ["UK Research and Innovation", "UK Research & Innovation"] }
    end

    factory :beis_organisation do
      name { "Department for Business, Energy and Industrial Strategy" }
      iati_reference { Organisation::SERVICE_OWNER_IATI_REFERENCE }
      role { "service_owner" }

      initialize_with do
        Organisation.find_or_create_by(
          name: name,
          iati_reference: iati_reference,
          role: role
        )
      end
    end
  end
end
