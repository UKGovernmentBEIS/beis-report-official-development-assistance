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

    wizard_status { "tied_status" } # this is the final step, aka "complete"

    association :organisation, factory: :organisation

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
  end

  trait :at_identifier_step do
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
