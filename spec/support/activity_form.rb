class ActivityForm
  include ActivityHelper
  include Capybara::DSL
  include RSpec::Matchers

  def initialize(activity:, fund:, level:)
    @activity = activity
    @fund = fund
    @level = level
  end

  def complete!
    send(:"fill_in_#{fund}_#{level}_activity_form")
  end

  def created_activity
    Activity.find_by(partner_organisation_identifier: activity.partner_organisation_identifier)
  end

  private

  attr_reader :activity, :fund, :level

  def fill_in_gcrf_programme_activity_form
    fill_in_identifier_step
    fill_in_purpose_step
    fill_in_objectives_step
    fill_in_sector_category_step
    fill_in_sector_step
    fill_in_programme_status
    fill_in_dates
    fill_in_benefitting_countries
    fill_in_gdi
    fill_in_aid_type
    fill_in_collaboration_type
    fill_in_sdgs_apply
    fill_in_covid19_related
    fill_in_gcrf_strategic_area
    fill_in_gcrf_challenge_area
    fill_in_oda_eligibility
    fill_in_commitment
  end

  def fill_in_newton_programme_activity_form
    fill_in_identifier_step
    fill_in_purpose_step
    fill_in_objectives_step
    fill_in_sector_category_step
    fill_in_sector_step
    fill_in_programme_status
    fill_in_country_partner_organisations
    fill_in_dates
    fill_in_benefitting_countries
    fill_in_gdi
    fill_in_aid_type
    fill_in_collaboration_type
    fill_in_sdgs_apply
    fill_in_fund_pillar
    fill_in_covid19_related
    fill_in_oda_eligibility
    fill_in_commitment
  end

  def fill_in_ooda_programme_activity_form
    fill_in_identifier_step
    fill_in_purpose_step
    fill_in_objectives_step
    fill_in_sector_category_step
    fill_in_sector_step
    fill_in_programme_status
    fill_in_dates
    fill_in_benefitting_countries
    fill_in_gdi
    fill_in_aid_type
    fill_in_collaboration_type
    fill_in_sdgs_apply
    fill_in_covid19_related
    fill_in_oda_eligibility
    fill_in_commitment
  end

  def fill_in_gcrf_project_activity_form
    fill_in_identifier_step
    fill_in_purpose_step
    fill_in_objectives_step
    fill_in_sector_category_step
    fill_in_sector_step
    fill_in_call_details
    fill_in_call_applications
    fill_in_programme_status
    fill_in_dates
    fill_in_benefitting_countries
    fill_in_gdi
    fill_in_aid_type
    fill_in_collaboration_type
    fill_in_sdgs_apply
    fill_in_policy_markers
    fill_in_covid19_related
    fill_in_gcrf_strategic_area
    fill_in_gcrf_challenge_area
    fill_in_channel_of_delivery_code
    fill_in_oda_eligibility
    fill_in_oda_eligibility_lead
    fill_in_named_contact
    fill_in_commitment
  end

  def fill_in_newton_project_activity_form
    fill_in_identifier_step
    fill_in_purpose_step
    fill_in_objectives_step
    fill_in_sector_category_step
    fill_in_sector_step
    fill_in_call_details
    fill_in_call_applications
    fill_in_programme_status
    fill_in_country_partner_organisations
    fill_in_dates
    fill_in_benefitting_countries
    fill_in_gdi
    fill_in_aid_type
    fill_in_collaboration_type
    fill_in_sdgs_apply
    fill_in_fund_pillar
    fill_in_policy_markers
    fill_in_covid19_related
    fill_in_channel_of_delivery_code
    fill_in_oda_eligibility
    fill_in_oda_eligibility_lead
    fill_in_named_contact
    fill_in_commitment
  end

  def fill_in_ispf_programme_activity_form
    fill_in_is_oda_step
    fill_in_identifier_step
    fill_in_linked_activity_step if ROLLOUT.active?(:activity_linking)
    fill_in_purpose_step
    fill_in_objectives_step if @activity.is_oda
    fill_in_sector_category_step
    fill_in_sector_step
    fill_in_programme_status
    fill_in_dates
    @activity.is_oda ? fill_in_ispf_oda_partner_countries : fill_in_ispf_non_oda_partner_countries

    if @activity.is_oda
      fill_in_benefitting_countries
      fill_in_gdi
      fill_in_aid_type
      fill_in_sdgs_apply
    end

    fill_in_ispf_themes
    fill_in_oda_eligibility if @activity.is_oda
    fill_in_tags
    fill_in_commitment
  end

  def fill_in_ispf_project_activity_form
    fill_in_identifier_step
    fill_in_linked_activity_step if ROLLOUT.active?(:activity_linking)
    fill_in_purpose_step
    fill_in_objectives_step if @activity.is_oda
    fill_in_sector_category_step
    fill_in_sector_step
    fill_in_call_details
    fill_in_call_applications
    fill_in_programme_status
    fill_in_dates
    @activity.is_oda ? fill_in_ispf_oda_partner_countries : fill_in_ispf_non_oda_partner_countries

    if @activity.is_oda
      fill_in_benefitting_countries
      fill_in_gdi
      fill_in_aid_type
      fill_in_collaboration_type
      fill_in_sdgs_apply
    end

    fill_in_ispf_themes

    if @activity.is_oda
      fill_in_policy_markers
      fill_in_covid19_related
      fill_in_channel_of_delivery_code
      fill_in_oda_eligibility
      fill_in_oda_eligibility_lead
    end

    fill_in_named_contact
    fill_in_implementing_organisation if @activity.third_party_project?
    fill_in_tags
    fill_in_commitment
  end

  def fill_in_is_oda_step
    expect(page).to have_content I18n.t("page_title.activity_form.show.is_oda")
    find("input[value='#{@activity.is_oda}']", visible: :all).click
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_identifier_step
    expect(page).to have_content I18n.t("page_title.activity_form.show.identifier")
    expect(page).to have_content I18n.t("form.hint.activity.partner_organisation_identifier")
    fill_in "activity[partner_organisation_identifier]", with: activity.partner_organisation_identifier
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_linked_activity_step
    expect(page).to have_content I18n.t(
      "page_title.activity_form.show.linked_activity",
      linked_activity_type: I18n.t("page_title.activity_form.show.linked_activity_type.is_oda.#{@activity.is_oda}")
    )
    if activity.linked_activity.present?
      select "#{activity.linked_activity.roda_identifier} (#{activity.linked_activity.title})", from: "activity[linked_activity_id]"
    end
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_purpose_step
    expect(page).to have_content I18n.t("page_title.activity_form.show.purpose", level: activity_level(activity.level))
    expect(page).to have_content custom_capitalisation(I18n.t("form.label.activity.title", level: activity_level(activity.level)))
    expect(page).to have_content I18n.t("form.label.activity.description")
    fill_in "activity[title]", with: activity.title
    fill_in "activity[description]", with: activity.description
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_objectives_step
    expect(page).to have_content I18n.t("page_title.activity_form.show.objectives", level: activity_level(activity.level))
    expect(page).to have_content I18n.t("form.hint.activity.objectives")
    fill_in "activity[objectives]", with: activity.objectives
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_sector_category_step
    expect(page).to have_content I18n.t("page_title.activity_form.show.sector_category", level: activity_level(activity.level))
    find("input[value='#{activity.sector_category}']", visible: :all).click
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_sector_step
    sector_category_name = I18n.t("activity.sector_category.#{activity.sector_category}")
    expect(page).to have_content I18n.t("page_title.activity_form.show.sector", sector_category: sector_category_name, level: activity_level(activity.level))
    choose activity.sector
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_programme_status
    expect(page).to have_content I18n.t("page_title.activity_form.show.programme_status")
    expect(page).to have_content "Delivery"
    expect(page).to have_content "Planned"
    expect(page).to have_content "Agreement in place"
    expect(page).to have_content "Call/Activity open"
    expect(page).to have_content "Review"
    expect(page).to have_content "Decided"
    expect(page).to have_content "Spend in progress"
    expect(page).to have_content "Finalisation"
    expect(page).to have_content "Completed"
    expect(page).to have_content "Stopped"
    expect(page).to have_content "Cancelled"

    find("input[value='#{activity.programme_status}']", visible: :all).click
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_call_details
    expect(page).to have_content I18n.t("page_title.activity_form.show.call_present", level: activity_level(activity.level))
    choose "Yes"
    click_button I18n.t("form.button.activity.submit")
    expect(page).to have_content I18n.t("page_title.activity_form.show.call_dates", level: activity_level(activity.level))

    expect(page).to have_content I18n.t("form.legend.activity.call_open_date")
    fill_in "activity[call_open_date(3i)]", with: activity.call_open_date.day
    fill_in "activity[call_open_date(2i)]", with: activity.call_open_date.month
    fill_in "activity[call_open_date(1i)]", with: activity.call_open_date.year

    expect(page).to have_content I18n.t("form.legend.activity.call_close_date")
    fill_in "activity[call_close_date(3i)]", with: activity.call_close_date.day
    fill_in "activity[call_close_date(2i)]", with: activity.call_close_date.month
    fill_in "activity[call_close_date(1i)]", with: activity.call_close_date.year

    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_call_applications
    expect(page).to have_content I18n.t("form.label.activity.total_applications")
    expect(page).to have_content I18n.t("form.hint.activity.total_applications")
    fill_in "activity[total_applications]", with: activity.total_applications

    expect(page).to have_content I18n.t("form.label.activity.total_awards")
    expect(page).to have_content I18n.t("form.hint.activity.total_awards")
    fill_in "activity[total_awards]", with: activity.total_awards

    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_country_partner_organisations
    expect(page).to have_content I18n.t("page_title.activity_form.show.country_partner_organisations")
    expect(page).to have_content I18n.t("form.hint.activity.country_partner_organisations")

    all("[name='activity[country_partner_organisations][]']").each_with_index do |element, index|
      break if activity.country_partner_organisations[index].blank?

      element.set(activity.country_partner_organisations[index])
    end

    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_dates
    expect(page).to have_content I18n.t("page_title.activity_form.show.dates", level: activity_level(activity.level))

    expect(page).to have_content I18n.t("form.legend.activity.planned_start_date")
    fill_in "activity[planned_start_date(3i)]", with: activity.planned_start_date.day
    fill_in "activity[planned_start_date(2i)]", with: activity.planned_start_date.month
    fill_in "activity[planned_start_date(1i)]", with: activity.planned_start_date.year

    expect(page).to have_content I18n.t("form.legend.activity.planned_end_date")
    fill_in "activity[planned_end_date(3i)]", with: activity.planned_end_date.day
    fill_in "activity[planned_end_date(2i)]", with: activity.planned_end_date.month
    fill_in "activity[planned_end_date(1i)]", with: activity.planned_end_date.year

    expect(page).to have_content I18n.t("form.legend.activity.actual_start_date")
    fill_in "activity[actual_start_date(3i)]", with: activity.actual_start_date.day
    fill_in "activity[actual_start_date(2i)]", with: activity.actual_start_date.month
    fill_in "activity[actual_start_date(1i)]", with: activity.actual_start_date.year

    expect(page).to have_content I18n.t("form.legend.activity.actual_end_date")
    fill_in "activity[actual_end_date(3i)]", with: activity.actual_end_date.day
    fill_in "activity[actual_end_date(2i)]", with: activity.actual_end_date.month
    fill_in "activity[actual_end_date(1i)]", with: activity.actual_end_date.year

    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_ispf_oda_partner_countries
    expect(page).to have_content I18n.t("page_title.activity_form.show.ispf_oda_partner_countries")
    expect(page).to have_content I18n.t("form.label.activity.ispf_oda_partner_countries")
    expect(page).to have_content I18n.t("form.label.activity.ispf_non_oda_partner_countries")

    activity.ispf_oda_partner_countries.each do |country_code|
      input = find("#activity-ispf-oda-partner-countries-#{country_code.downcase}-field")
      input.click
    end

    activity.ispf_non_oda_partner_countries.each do |country_code|
      input = find("#activity-ispf-non-oda-partner-countries-#{country_code.downcase}-field")
      input.click
    end

    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_ispf_non_oda_partner_countries
    expect(page).to have_content I18n.t("page_title.activity_form.show.ispf_non_oda_partner_countries")

    activity.ispf_non_oda_partner_countries.each do |country_code|
      input = find("input[value='#{country_code}']")
      input.click
    end

    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_benefitting_countries
    expect(page).to have_content I18n.t("page_title.activity_form.show.benefitting_countries")
    expect(page.html).to include I18n.t("form.hint.activity.benefitting_countries_html")

    activity.benefitting_countries.each do |country|
      find("input[value='#{country}']", visible: :all).click
    end

    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_gdi
    expect(page).to have_content I18n.t("page_title.activity_form.show.gdi")
    expect(page).to have_content I18n.t("form.hint.activity.gdi")

    find("input[value='#{activity.gdi}']", visible: :all).click
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_aid_type
    expect(page).to have_content I18n.t("page_title.activity_form.show.aid_type")
    expect(page).to have_content I18n.t("form.hint.activity.aid_type")
    choose("activity[aid_type]", option: activity.aid_type)
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_collaboration_type
    expect(page).to have_content I18n.t("page_title.activity_form.show.collaboration_type")
    choose("activity[collaboration_type]", option: activity.collaboration_type)

    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_sdgs_apply
    expect(page).to have_content I18n.t("page_title.activity_form.show.sustainable_development_goals")
    expect(page).to have_content I18n.t("form.hint.activity.sdgs_apply")
    choose I18n.t("form.label.activity.sdgs_apply_options.true")
    select I18n.t("form.label.activity.sdg_options.#{activity.sdg_1}"), from: "activity[sdg_1]"
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_fund_pillar
    expect(page).to have_content I18n.t("page_title.activity_form.show.fund_pillar")
    expect(page).to have_content I18n.t("form.hint.activity.fund_pillar")

    choose("activity[fund_pillar]", option: activity.fund_pillar)
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_policy_markers
    expect(page).to have_content I18n.t("page_title.activity_form.show.policy_markers")
    expect(page).to have_content I18n.t("form.hint.activity.policy_markers.title")

    not_assessed_code = policy_markers_radio_options.find { |option| option.value == "not_assessed" }
    expect(page).to have_content not_assessed_code.label
    expect(page).to have_content not_assessed_code.description

    fill_in_policy_marker("policy_marker_gender", activity.policy_marker_gender)
    fill_in_policy_marker("policy_marker_climate_change_adaptation", activity.policy_marker_climate_change_adaptation)
    fill_in_policy_marker("policy_marker_climate_change_mitigation", activity.policy_marker_climate_change_mitigation)
    fill_in_policy_marker("policy_marker_biodiversity", activity.policy_marker_biodiversity)
    fill_in_policy_marker("policy_marker_desertification", activity.policy_marker_desertification)
    fill_in_policy_marker("policy_marker_disability", activity.policy_marker_disability)
    fill_in_policy_marker("policy_marker_disaster_risk_reduction", activity.policy_marker_disaster_risk_reduction)
    fill_in_policy_marker("policy_marker_nutrition", activity.policy_marker_nutrition)

    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_covid19_related
    expect(page).to have_content I18n.t("page_title.activity_form.show.covid19_related")
    choose("activity[covid19_related]", option: activity.covid19_related)
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_gcrf_strategic_area
    expect(page).to have_content I18n.t("page_title.activity_form.show.gcrf_strategic_area")
    expect(page).to have_content I18n.t("form.hint.activity.gcrf_strategic_area")
    activity.gcrf_strategic_area.each do |gcrf_strategic_area|
      find("input[value='#{gcrf_strategic_area}']", visible: :all).click
    end
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_gcrf_challenge_area
    expect(page).to have_content I18n.t("page_title.activity_form.show.gcrf_challenge_area")
    expect(page).to have_content I18n.t("form.hint.activity.gcrf_challenge_area")
    choose("activity[gcrf_challenge_area]", option: activity.gcrf_challenge_area)
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_ispf_themes
    expect(page).to have_content I18n.t("page_title.activity_form.show.ispf_themes")
    activity.ispf_themes.each do |theme|
      find("input[value='#{theme}']", visible: :all).click
    end
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_channel_of_delivery_code
    expect(page).to have_content I18n.t("page_title.activity_form.show.channel_of_delivery_code")
    choose("activity[channel_of_delivery_code]", option: activity.channel_of_delivery_code)
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_oda_eligibility
    expect(page).to have_content I18n.t("page_title.activity_form.show.oda_eligibility")
    expect(page).to have_content I18n.t("form.hint.activity.oda_eligibility")
    choose("activity[oda_eligibility]", option: activity.oda_eligibility)
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_oda_eligibility_lead
    expect(page).to have_content I18n.t("page_title.activity_form.show.oda_eligibility_lead")
    expect(page).to have_content I18n.t("form.hint.activity.oda_eligibility_lead")
    fill_in "activity[oda_eligibility_lead]", with: activity.oda_eligibility_lead
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_implementing_organisation
    expect(page).to have_content I18n.t("page_title.activity_form.show.implementing_organisation")
    select(activity.implementing_organisations.first.name, from: I18n.t("form.label.activity.implementing_organisation"))
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_named_contact
    expect(page).to have_content I18n.t("page_title.activity_form.show.uk_po_named_contact")
    fill_in "activity[uk_po_named_contact]", with: activity.uk_po_named_contact
    click_button I18n.t("form.button.activity.submit")
  end

  def activity_level(level)
    I18n.t("page_content.activity.level.#{level}")
  end

  def fill_in_policy_marker(key, value)
    expect(page).to have_content I18n.t("form.legend.activity.#{key}")
    find("input[name='activity[#{key}]'][value='#{value}']").click
  end

  def fill_in_tags
    expect(page).to have_content I18n.t("page_title.activity_form.show.tags")
    activity.tags&.each do |tag|
      find("input[value='#{tag}']", visible: :all).click
    end
    click_button I18n.t("form.button.activity.submit")
  end

  def fill_in_commitment
    optional = activity.third_party_project? ? "" : " (optional)"
    expect(page).to have_content I18n.t("page_title.activity_form.show.commitment", optional: optional)
    fill_in "activity[commitment][value]", with: activity.commitment.value
    click_button I18n.t("form.button.activity.submit")
  end
end
