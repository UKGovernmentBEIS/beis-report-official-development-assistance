FactoryBot.define do
  factory :__activity do
    title { Faker::Lorem.sentence }
    delivery_partner_identifier { "GCRF-#{Faker::Alphanumeric.alpha(number: 5).upcase!}" }
    roda_identifier_fragment { Faker::Alphanumeric.alpha(number: 5) }
    roda_identifier { nil }
    beis_identifier { nil }
    description { Faker::Lorem.paragraph }
    sector_category { "111" }
    sector { "11110" }
    source_fund_code { Fund.by_short_name("NF").id }
    programme_status { 7 }
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
    aid_type { "D01" }
    level { :fund }
    publish_to_iati { true }
    gcrf_strategic_area { ["17A", "RF"] }
    gcrf_challenge_area { 0 }
    oda_eligibility_lead { Faker::Name.name }
    uk_dp_named_contact { Faker::Name.name }
    fund_pillar { "0" }
    channel_of_delivery_code { "11000" }

    form_state { "complete" }

    before(:create) do |activity|
      if activity.roda_identifier.blank? && activity.parent.present?
        activity.roda_identifier = Activity::RodaIdentifierGenerator.new(
          parent_activity: activity.parent,
          extending_organisation: activity.extending_organisation,
        ).generate
      end
    end

    trait :with_report do
      after(:create) do |activity|
        fund = activity.associated_fund
        create(:report, :active, fund: fund, organisation: activity.organisation)
      end
    end

    factory :fund_activity do
      level { :fund }

      association :organisation, factory: :beis_organisation
      association :extending_organisation, factory: :beis_organisation

      trait :gcrf do
        roda_identifier { "GCRF" }
        title { "Global Challenges Research Fund (GCRF)" }
        source_fund_code { Fund.by_short_name("GCRF").id }

        initialize_with do
          Activity.find_or_initialize_by(roda_identifier_fragment: "GCRF")
        end
      end

      trait :newton do
        roda_identifier { "NF" }
        title { "Newton Fund" }
        source_fund_code { Fund.by_short_name("NF").id }

        initialize_with do
          Activity.find_or_initialize_by(roda_identifier_fragment: "NF")
        end
      end
    end

    factory :programme_activity do
      parent factory: :fund_activity
      level { :programme }
      objectives { Faker::Lorem.paragraph }
      country_delivery_partners { ["National Council for the State Funding Agencies (CONFAP)"] }
      collaboration_type { "1" }

      association :organisation, factory: :beis_organisation
      association :extending_organisation, factory: :delivery_partner_organisation

      trait :newton_funded do
        source_fund_code { Fund.by_short_name("NF").id }
        parent do
          Activity.fund.find_by(source_fund_code: Fund.by_short_name("NF").id) || create(:fund_activity, :newton)
        end
      end

      trait :gcrf_funded do
        source_fund_code { Fund.by_short_name("GCRF").id }
        parent do
          Activity.fund.find_by(source_fund_code: Fund.by_short_name("GCRF").id) || create(:fund_activity, :gcrf)
        end
      end
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

      association :organisation, factory: :delivery_partner_organisation
      association :extending_organisation, factory: :delivery_partner_organisation

      factory :project_activity_with_implementing_organisations do
        transient do
          implementing_organisations_count { 3 }
        end

        after(:create) do |project_activity, evaluator|
          create_list(:implementing_organisation, evaluator.implementing_organisations_count, activity: project_activity)
          project_activity.reload
        end
      end

      trait :newton_funded do
        source_fund_code { Fund.by_short_name("NF").id }
        parent factory: [:programme_activity, :newton_funded]
      end

      trait :gcrf_funded do
        source_fund_code { Fund.by_short_name("GCRF").id }
        parent factory: [:programme_activity, :gcrf_funded]
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

      association :organisation, factory: :delivery_partner_organisation
      association :extending_organisation, factory: :delivery_partner_organisation

      trait :newton_funded do
        source_fund_code { Fund.by_short_name("NF").id }
        parent factory: [:project_activity, :newton_funded]
      end

      trait :gcrf_funded do
        source_fund_code { Fund.by_short_name("GCRF").id }
        parent factory: [:project_activity, :gcrf_funded]
      end
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
    country_delivery_partners { nil }
    planned_start_date { nil }
    planned_end_date { nil }
    actual_start_date { nil }
    actual_end_date { nil }
    geography { nil }
    recipient_region { nil }
    recipient_country { nil }
    collaboration_type { nil }
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
    country_delivery_partners { nil }
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
    country_delivery_partners { nil }
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

  trait :at_collaboration_type_step do
    form_state { "collaboration_type" }
    collaboration_type { nil }
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

  trait :with_transparency_identifier do
    after(:create) do |activity|
      parent_identifier = activity.parent.present? ? "#{activity.parent.delivery_partner_identifier}-" : ""
      activity.transparency_identifier = "#{parent_identifier}#{activity.delivery_partner_identifier}"
      activity.save
    end
  end
end
