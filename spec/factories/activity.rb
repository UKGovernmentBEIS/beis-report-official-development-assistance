FactoryBot.define do
  factory :activity do
    title { Faker::Lorem.sentence }
    identifier { "GCRF-#{Faker::Alphanumeric.alpha(number: 5).upcase!}" }
    description { Faker::Lorem.paragraph }
    sector_category { "111" }
    sector { "11110" }
    programme_status { "07" }
    planned_start_date { Date.today }
    planned_end_date { Date.tomorrow }
    actual_start_date { Date.yesterday }
    actual_end_date { Date.today }
    geography { :recipient_region }
    recipient_region { "489" }
    recipient_country { nil }
    flow { "10" }
    aid_type { "A01" }
    level { :fund }
    publish_to_iati { true }

    form_state { "complete" }

    association :organisation, factory: :organisation
    association :reporting_organisation, factory: :beis_organisation

    trait :with_report do
      after(:create) do |activity|
        fund = activity.associated_fund
        create(:report, :active, fund: fund, organisation: activity.organisation)
      end
    end

    factory :fund_activity do
      level { :fund }
      funding_organisation_name { "HM Treasury" }
      funding_organisation_reference { "GB-GOV-2" }
      funding_organisation_type { "10" }
      accountable_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      accountable_organisation_reference { "GB-GOV-13" }
      accountable_organisation_type { "10" }

      association :organisation, factory: :beis_organisation
      association :extending_organisation, factory: :beis_organisation
      association :reporting_organisation, factory: :beis_organisation
    end

    factory :programme_activity do
      parent factory: :fund_activity
      level { :programme }
      funding_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      funding_organisation_reference { "GB-GOV-13" }
      funding_organisation_type { "10" }
      accountable_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      accountable_organisation_reference { "GB-GOV-13" }
      accountable_organisation_type { "10" }

      association :organisation, factory: :beis_organisation
      association :extending_organisation, factory: :delivery_partner_organisation
      association :reporting_organisation, factory: :beis_organisation
    end

    factory :project_activity do
      parent factory: :programme_activity
      level { :project }
      call_present { "true" }
      call_open_date { Date.yesterday }
      call_close_date { Date.tomorrow }
      funding_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      funding_organisation_reference { "GB-GOV-13" }
      funding_organisation_type { "10" }
      accountable_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      accountable_organisation_reference { "GB-GOV-13" }
      accountable_organisation_type { "10" }

      association :extending_organisation, factory: :delivery_partner_organisation
      association :reporting_organisation, factory: :beis_organisation

      factory :project_activity_with_implementing_organisations do
        transient do
          implementing_organisations_count { 3 }
        end

        after(:create) do |project_activity, evaluator|
          create_list(:implementing_organisation, evaluator.implementing_organisations_count, activity: project_activity)
        end
      end
    end

    factory :third_party_project_activity do
      parent factory: :project_activity
      level { :third_party_project }
      call_present { "true" }
      call_open_date { Date.yesterday }
      call_close_date { Date.tomorrow }
      funding_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      funding_organisation_reference { "GB-GOV-13" }
      funding_organisation_type { "10" }
      accountable_organisation_name { "Department for Business, Energy and Industrial Strategy" }
      accountable_organisation_reference { "GB-GOV-13" }
      accountable_organisation_type { "10" }

      association :extending_organisation, factory: :delivery_partner_organisation
      association :reporting_organisation, factory: :beis_organisation
    end
  end

  trait :at_identifier_step do
    identifier { nil }
    form_state { "identifier" }
    title { nil }
    description { nil }
    sector_category { nil }
    sector { nil }
    call_present { nil }
    programme_status { nil }
    planned_start_date { nil }
    planned_end_date { nil }
    actual_start_date { nil }
    actual_end_date { nil }
    geography { nil }
    recipient_region { nil }
    recipient_country { nil }
    flow { nil }
    aid_type { nil }
  end

  trait :at_purpose_step do
    form_state { "identifier" }
    title { nil }
    description { nil }
    sector { nil }
    call_present { nil }
    programme_status { nil }
    planned_start_date { nil }
    planned_end_date { nil }
    actual_start_date { nil }
    actual_end_date { nil }
    geography { nil }
    recipient_region { nil }
    recipient_country { nil }
    flow { nil }
    aid_type { nil }
  end

  trait :at_region_step do
    form_state { "region" }
    recipient_country { nil }
    flow { nil }
    aid_type { nil }
  end

  trait :at_geography_step do
    form_state { "geography" }
    recipient_region { nil }
    recipient_country { nil }
    flow { nil }
    aid_type { nil }
  end

  trait :nil_form_state do
    form_state { nil }
  end

  trait :blank_form_state do
    form_state { "blank" }
    title { nil }
    description { nil }
    sector { nil }
    call_present { nil }
    programme_status { nil }
    planned_start_date { nil }
    planned_end_date { nil }
    actual_start_date { nil }
    actual_end_date { nil }
    geography { nil }
    recipient_region { nil }
    recipient_country { nil }
    flow { nil }
    aid_type { nil }
    extending_organisation_id { nil }
    parent { nil }
    level { nil }
  end

  trait :level_form_state do
    form_state { "level" }
    level { nil }
    identifier { nil }
    title { nil }
    description { nil }
    sector { nil }
    call_present { nil }
    programme_status { nil }
    planned_start_date { nil }
    planned_end_date { nil }
    actual_start_date { nil }
    actual_end_date { nil }
    geography { nil }
    recipient_region { nil }
    recipient_country { nil }
    flow { nil }
    aid_type { nil }
    extending_organisation_id { nil }
    parent { nil }
  end

  trait :parent_form_state do
    form_state { "parent" }
    level { "programme" }
    identifier { nil }
    title { nil }
    description { nil }
    sector { nil }
    programme_status { nil }
    planned_start_date { nil }
    planned_end_date { nil }
    actual_start_date { nil }
    actual_end_date { nil }
    geography { nil }
    recipient_region { nil }
    recipient_country { nil }
    flow { nil }
    aid_type { nil }
    extending_organisation_id { nil }
    parent { nil }
  end

  trait :with_transparency_identifier do
    after(:create) do |activity|
      parent_identifier = activity.parent.present? ? "#{activity.parent.identifier}-" : ""
      activity.transparency_identifier = "#{parent_identifier}#{activity.identifier}"
      activity.save
    end
  end
end
