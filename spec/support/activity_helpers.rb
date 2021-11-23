module ActivityHelpers
  def page_displays_an_activity(activity_presenter:)
    click_on t("tabs.activity.details")

    expect(page).to have_content t("activerecord.attributes.activity.organisation")
    expect(page).to have_content activity_presenter.organisation.name

    expect(page).to have_content t("activerecord.attributes.activity.level")
    expect(page).to have_content activity_presenter.level

    unless activity_presenter.fund?
      expect(page).to have_content t("activerecord.attributes.activity.parent")
      expect(page).to have_content activity_presenter.parent_title
    end

    expect(page).to have_content t("activerecord.attributes.activity.delivery_partner_identifier")
    expect(page).to have_content activity_presenter.delivery_partner_identifier

    expect(page).to have_content custom_capitalisation(t("activerecord.attributes.activity.title", level: activity_presenter.level))
    expect(page).to have_content activity_presenter.title

    expect(page).to have_content t("activerecord.attributes.activity.description")
    expect(page).to have_content activity_presenter.description

    expect(page).to have_content t("activerecord.attributes.activity.sector", level: activity_presenter.level)
    expect(page).to have_content activity_presenter.sector

    unless activity_presenter.fund?
      expect(page).to have_content t("activerecord.attributes.activity.programme_status")
      expect(page).to have_content activity_presenter.programme_status
    end

    expect(page).to have_content t("activerecord.attributes.activity.planned_start_date")
    expect(page).to have_content activity_presenter.planned_start_date

    expect(page).to have_content t("activerecord.attributes.activity.planned_end_date")
    expect(page).to have_content activity_presenter.planned_end_date

    expect(page).to have_content t("activerecord.attributes.activity.actual_start_date")
    expect(page).to have_content activity_presenter.actual_start_date

    expect(page).to have_content t("activerecord.attributes.activity.actual_end_date")
    expect(page).to have_content activity_presenter.actual_end_date

    expect(page).to have_content t("activerecord.attributes.activity.benefitting_countries")
    expect(page).to have_content activity_presenter.recipient_region

    expect(page).to have_content t("activerecord.attributes.activity.aid_type")
    expect(page).to have_content activity_presenter.aid_type
  end

  def associated_fund_is_newton?(activity)
    return if activity.nil?

    activity.associated_fund.roda_identifier == "NF"
  end
end
