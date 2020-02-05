FactoryBot.define do
  sequence(:identifier) { |n| "GB-GOV-13-GCRF-#{n}" }

  factory :activity do
    title { Faker::Lorem.sentence }
    identifier
    description { Faker::Lorem.paragraph }
    sector { "99" }
    status { "2" }
    planned_start_date { Date.today }
    planned_end_date { Date.tomorrow }
    actual_start_date { Date.today }
    actual_end_date { Date.tomorrow }
    recipient_region { "489" }
    flow { "10" }
    finance { "110" }
    aid_type { "A01" }
    tied_status { "3" }
    level { :fund }

    wizard_status { "complete" } # wizard is complete

    association :organisation, factory: :organisation

    factory :fund_activity do
      level { :fund }
      funding_organisation_name { "HM Treasury" }
      funding_organisation_reference { "GB-GOV-2" }
      funding_organisation_type { "10" }
      accountable_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      accountable_organisation_reference { "GB-GOV-13" }
      accountable_organisation_type { "10" }
      extending_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      extending_organisation_reference { "GB-GOV-13" }
      extending_organisation_type { "10" }
    end

    factory :programme_activity do
      level { :programme }
      funding_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      funding_organisation_reference { "GB-GOV-13" }
      funding_organisation_type { "10" }
      accountable_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      accountable_organisation_reference { "GB-GOV-13" }
      accountable_organisation_type { "10" }
    end
  end

  trait :at_identifier_step do
    identifier { nil }
    wizard_status { "identifier" }
    title { nil }
    description { nil }
    sector { nil }
    status { nil }
    planned_start_date { nil }
    planned_end_date { nil }
    actual_start_date { nil }
    actual_end_date { nil }
    recipient_region { nil }
    flow { nil }
    finance { nil }
    aid_type { nil }
    tied_status { nil }
  end

  trait :at_purpose_step do
    wizard_status { "identifier" }
    title { nil }
    description { nil }
    sector { nil }
    status { nil }
    planned_start_date { nil }
    planned_end_date { nil }
    actual_start_date { nil }
    actual_end_date { nil }
    recipient_region { nil }
    flow { nil }
    finance { nil }
    aid_type { nil }
    tied_status { nil }
  end

  trait :at_country_step do
    wizard_status { "country" }
    flow { nil }
    finance { nil }
    aid_type { nil }
    tied_status { nil }
  end

  trait :nil_wizard_status do
    wizard_status { nil }
  end
end
