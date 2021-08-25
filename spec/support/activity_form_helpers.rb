module ActivityFormHelpers
  include ActivityHelper

  def fill_in_identifier_step(activity)
    expect(page).to have_content t("form.label.activity.delivery_partner_identifier")
    expect(page).to have_content t("form.hint.activity.delivery_partner_identifier")
    fill_in "activity[delivery_partner_identifier]", with: activity.delivery_partner_identifier
    click_button t("form.button.activity.submit")
  end

  def fill_in_purpose_step(activity)
    expect(page).to have_content t("form.legend.activity.purpose", level: activity_level(activity.level))
    expect(page).to have_content custom_capitalisation(t("form.label.activity.title", level: t("page_content.activity.level.programme")))
    expect(page).to have_content t("form.label.activity.description")
    fill_in "activity[title]", with: activity.title
    fill_in "activity[description]", with: activity.description
    click_button t("form.button.activity.submit")
  end

  def fill_in_objectives_step(activity)
    expect(page).to have_content t("form.legend.activity.objectives", level: activity_level(activity.level))
    expect(page).to have_content t("form.hint.activity.objectives")
    fill_in "activity[objectives]", with: activity.objectives
    click_button t("form.button.activity.submit")
  end

  def fill_in_sector_category_step(activity)
    expect(page).to have_content t("form.legend.activity.sector_category", level: activity_level(activity.level))
    expect(page).to have_content(
      ActionView::Base.full_sanitizer.sanitize(
        t("form.legend.activity.sector_category", level: t("page_content.activity.level.#{activity.level}"))
      )
    )
    find("input[value='#{activity.sector_category}']", visible: :all).click
    click_button t("form.button.activity.submit")
  end

  def fill_in_sector_step(activity)
    sector_category_name = t("activity.sector_category.#{activity.sector_category}")
    expect(page).to have_content t("form.legend.activity.sector", sector_category: sector_category_name, level: activity_level(activity.level))
    choose activity.sector
    click_button t("form.button.activity.submit")
  end

  def fill_in_programme_status(activity)
    expect(page).to have_content t("form.legend.activity.programme_status")
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
    click_button t("form.button.activity.submit")
  end

  def fill_in_country_delivery_partners(activity)
    expect(page).to have_content t("form.legend.activity.country_delivery_partners")
    expect(page).to have_content t("form.hint.activity.country_delivery_partners")

    all("[name='activity[country_delivery_partners][]']").each_with_index do |element, index|
      break if activity.country_delivery_partners[index].blank?

      element.set(activity.country_delivery_partners[index])
    end

    click_button t("form.button.activity.submit")
  end

  def fill_in_dates(activity)
    expect(page).to have_content t("page_title.activity_form.show.dates", level: activity_level(activity.level))

    expect(page).to have_content t("form.legend.activity.planned_start_date")
    fill_in "activity[planned_start_date(3i)]", with: activity.planned_start_date.day
    fill_in "activity[planned_start_date(2i)]", with: activity.planned_start_date.month
    fill_in "activity[planned_start_date(1i)]", with: activity.planned_start_date.year

    expect(page).to have_content t("form.legend.activity.planned_end_date")
    fill_in "activity[planned_end_date(3i)]", with: activity.planned_end_date.day
    fill_in "activity[planned_end_date(2i)]", with: activity.planned_end_date.month
    fill_in "activity[planned_end_date(1i)]", with: activity.planned_end_date.year

    expect(page).to have_content t("form.legend.activity.actual_start_date")
    fill_in "activity[actual_start_date(3i)]", with: activity.actual_start_date.day
    fill_in "activity[actual_start_date(2i)]", with: activity.actual_start_date.month
    fill_in "activity[actual_start_date(1i)]", with: activity.actual_start_date.year

    expect(page).to have_content t("form.legend.activity.actual_end_date")
    fill_in "activity[actual_end_date(3i)]", with: activity.actual_end_date.day
    fill_in "activity[actual_end_date(2i)]", with: activity.actual_end_date.month
    fill_in "activity[actual_end_date(1i)]", with: activity.actual_end_date.year

    click_button t("form.button.activity.submit")
  end

  def fill_in_benefitting_countries(activity)
    expect(page).to have_content t("form.legend.activity.benefitting_countries")
    expect(page).to have_content t("form.hint.activity.benefitting_countries")

    activity.benefitting_countries.each do |country|
      find("input[value='#{country}']", visible: :all).click
    end

    click_button t("form.button.activity.submit")
  end

  def fill_in_gdi(activity)
    expect(page).to have_content t("form.label.activity.gdi")
    expect(page).to have_content t("form.hint.activity.gdi")

    find("input[value='#{activity.gdi}']", visible: :all).click
    click_button t("form.button.activity.submit")
  end

  def fill_in_aid_type(activity)
    expect(page).to have_content t("form.legend.activity.aid_type")
    expect(page).to have_content t("form.hint.activity.aid_type")
    choose("activity[aid_type]", option: activity.aid_type)
    click_button t("form.button.activity.submit")
  end

  def fill_in_collaboration_type(activity)
    expect(page).to have_content t("form.label.activity.collaboration_type")
    choose("activity[collaboration_type]", option: activity.collaboration_type)

    click_button t("form.button.activity.submit")
  end

  def fill_in_sdgs_apply(activity)
    expect(page).to have_content t("form.legend.activity.sdgs_apply")
    expect(page).to have_content t("form.hint.activity.sdgs_apply")
    choose t("form.label.activity.sdgs_apply_options.true")
    select t("form.label.activity.sdg_options.#{activity.sdg_1}"), from: "activity[sdg_1]"
    click_button t("form.button.activity.submit")
  end

  def fill_in_fund_pillar(activity)
    expect(page).to have_content t("form.legend.activity.fund_pillar")
    expect(page).to have_content t("form.hint.activity.fund_pillar")

    choose("activity[fund_pillar]", option: activity.fund_pillar)
    click_button t("form.button.activity.submit")
  end

  def fill_in_covid19_related(activity)
    expect(page).to have_content t("form.legend.activity.covid19_related")
    choose("activity[covid19_related]", option: activity.covid19_related)
    click_button t("form.button.activity.submit")
  end

  def fill_in_gcrf_strategic_area(activity)
    expect(page).to have_content t("form.legend.activity.gcrf_strategic_area")
    expect(page).to have_content t("form.hint.activity.gcrf_strategic_area")
    activity.gcrf_strategic_area.each do |gcrf_strategic_area|
      find("input[value='#{gcrf_strategic_area}']", visible: :all).click
    end
    click_button t("form.button.activity.submit")
  end

  def fill_in_gcrf_challenge_area(activity)
    expect(page).to have_content t("form.legend.activity.gcrf_challenge_area")
    expect(page).to have_content t("form.hint.activity.gcrf_challenge_area")
    choose("activity[gcrf_challenge_area]", option: activity.gcrf_challenge_area)
    click_button t("form.button.activity.submit")
  end

  def fill_in_oda_eligibility(activity)
    expect(page).to have_content t("form.legend.activity.oda_eligibility")
    expect(page).to have_content t("form.hint.activity.oda_eligibility")
    choose("activity[oda_eligibility]", option: activity.oda_eligibility)
    click_button t("form.button.activity.submit")
  end

  private def activity_level(level)
    t("page_content.activity.level.#{level}")
  end
end
