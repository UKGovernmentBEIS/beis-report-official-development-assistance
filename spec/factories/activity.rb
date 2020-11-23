FactoryBot.define do
  factory :activity do
    title { Faker::Lorem.sentence }
    delivery_partner_identifier { "GCRF-#{Faker::Alphanumeric.alpha(number: 5).upcase!}" }
    roda_identifier_fragment { Faker::Alphanumeric.alpha(number: 5) }
    roda_identifier_compound { nil }
    beis_id { nil }
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
    requires_additional_benefitting_countries { true }
    intended_beneficiaries { ["CU", "DM", "DO"] }
    gdi { "4" }
    fstc_applies { true }
    flow { "10" }
    aid_type { "B02" }
    level { :fund }
    publish_to_iati { true }
    oda_eligibility_lead { Faker::Name.name }

    form_state { "complete" }

    association :organisation, factory: :organisation
    association :reporting_organisation, factory: :beis_organisation

    before(:create) do |activity|
      activity.cache_roda_identifier
    end

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
      objectives { Faker::Lorem.paragraph }
      collaboration_type { "1" }
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
      objectives { Faker::Lorem.paragraph }
      call_present { "true" }
      call_open_date { Date.yesterday }
      call_close_date { Date.tomorrow }
      collaboration_type { "1" }
      total_applications { "25" }
      total_awards { "12" }
      policy_marker_gender { "not_assessed" }
      policy_marker_climate_change_adaptation { "not_assessed" }
      policy_marker_climate_change_mitigation { "not_assessed" }
      policy_marker_biodiversity { "not_assessed" }
      policy_marker_desertification { "not_assessed" }
      policy_marker_disability { "not_assessed" }
      policy_marker_disaster_risk_reduction { "not_assessed" }
      policy_marker_nutrition { "not_assessed" }
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
      objectives { Faker::Lorem.paragraph }
      call_present { "true" }
      call_open_date { Date.yesterday }
      call_close_date { Date.tomorrow }
      collaboration_type { "1" }
      total_applications { "25" }
      total_awards { "12" }
      policy_marker_gender { "not_assessed" }
      policy_marker_climate_change_adaptation { "not_assessed" }
      policy_marker_climate_change_mitigation { "not_assessed" }
      policy_marker_biodiversity { "not_assessed" }
      policy_marker_desertification { "not_assessed" }
      policy_marker_disability { "not_assessed" }
      policy_marker_disaster_risk_reduction { "not_assessed" }
      policy_marker_nutrition { "not_assessed" }
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
    form_state { "identifier" }
    delivery_partner_identifier { nil }
    roda_identifier_fragment { nil }
    title { nil }
    description { nil }
    objectives { nil }
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
    collaboration_type { nil }
    flow { nil }
    aid_type { nil }
    policy_marker_gender { nil }
    policy_marker_climate_change_adaptation { nil }
    policy_marker_climate_change_mitigation { nil }
    policy_marker_biodiversity { nil }
    policy_marker_desertification { nil }
    policy_marker_disability { nil }
    policy_marker_disaster_risk_reduction { nil }
    policy_marker_nutrition { nil }
    oda_eligibility_lead { nil }
  end

  trait :at_roda_identifier_step do
    form_state { "roda_identifier" }
    roda_identifier_fragment { nil }
    title { nil }
    description { nil }
    objectives { nil }
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
    intended_beneficiaries { nil }
    gdi { nil }
    collaboration_type { nil }
    flow { nil }
    aid_type { nil }
    policy_marker_gender { nil }
    policy_marker_climate_change_adaptation { nil }
    policy_marker_climate_change_mitigation { nil }
    policy_marker_biodiversity { nil }
    policy_marker_desertification { nil }
    policy_marker_disability { nil }
    policy_marker_disaster_risk_reduction { nil }
    policy_marker_nutrition { nil }
    oda_eligibility_lead { nil }
  end

  trait :at_purpose_step do
    form_state { "purpose" }
    title { nil }
    description { nil }
    objectives { nil }
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
    intended_beneficiaries { nil }
    gdi { nil }
    collaboration_type { nil }
    flow { nil }
    aid_type { nil }
    policy_marker_gender { nil }
    policy_marker_climate_change_adaptation { nil }
    policy_marker_climate_change_mitigation { nil }
    policy_marker_biodiversity { nil }
    policy_marker_desertification { nil }
    policy_marker_disability { nil }
    policy_marker_disaster_risk_reduction { nil }
    policy_marker_nutrition { nil }
    oda_eligibility_lead { nil }
  end

  trait :at_region_step do
    form_state { "region" }
    recipient_country { nil }
    intended_beneficiaries { nil }
    gdi { nil }
    collaboration_type { nil }
    flow { nil }
    aid_type { nil }
    policy_marker_gender { nil }
    policy_marker_climate_change_adaptation { nil }
    policy_marker_climate_change_mitigation { nil }
    policy_marker_biodiversity { nil }
    policy_marker_desertification { nil }
    policy_marker_disability { nil }
    policy_marker_disaster_risk_reduction { nil }
    policy_marker_nutrition { nil }
    oda_eligibility_lead { nil }
  end

  trait :at_geography_step do
    form_state { "geography" }
    recipient_region { nil }
    recipient_country { nil }
    intended_beneficiaries { nil }
    gdi { nil }
    collaboration_type { nil }
    flow { nil }
    aid_type { nil }
    policy_marker_gender { nil }
    policy_marker_climate_change_adaptation { nil }
    policy_marker_climate_change_mitigation { nil }
    policy_marker_biodiversity { nil }
    policy_marker_desertification { nil }
    policy_marker_disability { nil }
    policy_marker_disaster_risk_reduction { nil }
    policy_marker_nutrition { nil }
    oda_eligibility_lead { nil }
  end

  trait :nil_form_state do
    form_state { nil }
  end

  trait :at_collaboration_type_step do
    form_state { "collaboration_type" }
    collaboration_type { nil }
    flow { nil }
    aid_type { nil }
    policy_marker_gender { nil }
    policy_marker_climate_change_adaptation { nil }
    policy_marker_climate_change_mitigation { nil }
    policy_marker_biodiversity { nil }
    policy_marker_desertification { nil }
    policy_marker_disability { nil }
    policy_marker_disaster_risk_reduction { nil }
    policy_marker_nutrition { nil }
    oda_eligibility_lead { nil }
  end

  trait :at_sustainable_development_goals_step do
    form_state { "sustainable_development_goals" }

    sdgs_apply { false }
    sdg_1 { nil }
    sdg_2 { nil }
    sdg_3 { nil }
  end

  trait :blank_form_state do
    form_state { "blank" }
    title { nil }
    description { nil }
    objectives { nil }
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
    intended_beneficiaries { nil }
    gdi { nil }
    collaboration_type { nil }
    flow { nil }
    aid_type { nil }
    policy_marker_gender { nil }
    policy_marker_climate_change_adaptation { nil }
    policy_marker_climate_change_mitigation { nil }
    policy_marker_biodiversity { nil }
    policy_marker_desertification { nil }
    policy_marker_disability { nil }
    policy_marker_disaster_risk_reduction { nil }
    policy_marker_nutrition { nil }
    extending_organisation_id { nil }
    parent { nil }
    level { nil }
    oda_eligibility_lead { nil }
  end

  trait :level_form_state do
    form_state { "level" }
    level { nil }
    delivery_partner_identifier { nil }
    title { nil }
    description { nil }
    objectives { nil }
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
    intended_beneficiaries { nil }
    gdi { nil }
    collaboration_type { nil }
    flow { nil }
    aid_type { nil }
    policy_marker_gender { nil }
    policy_marker_climate_change_adaptation { nil }
    policy_marker_climate_change_mitigation { nil }
    policy_marker_biodiversity { nil }
    policy_marker_desertification { nil }
    policy_marker_disability { nil }
    policy_marker_disaster_risk_reduction { nil }
    policy_marker_nutrition { nil }
    extending_organisation_id { nil }
    parent { nil }
    oda_eligibility_lead { nil }
  end

  trait :parent_form_state do
    form_state { "parent" }
    level { "programme" }
    delivery_partner_identifier { nil }
    title { nil }
    description { nil }
    objectives { nil }
    sector { nil }
    programme_status { nil }
    planned_start_date { nil }
    planned_end_date { nil }
    actual_start_date { nil }
    actual_end_date { nil }
    geography { nil }
    recipient_region { nil }
    recipient_country { nil }
    intended_beneficiaries { nil }
    gdi { nil }
    collaboration_type { nil }
    flow { nil }
    aid_type { nil }
    extending_organisation_id { nil }
    parent { nil }
    oda_eligibility_lead { nil }
  end

  trait :with_transparency_identifier do
    after(:create) do |activity|
      parent_identifier = activity.parent.present? ? "#{activity.parent.delivery_partner_identifier}-" : ""
      activity.transparency_identifier = "#{parent_identifier}#{activity.delivery_partner_identifier}"
      activity.save
    end
  end
end
