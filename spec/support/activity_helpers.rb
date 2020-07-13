module ActivityHelpers
  def page_displays_an_activity(activity_presenter:)
    click_on I18n.t("tabs.activity.details")

    expect(page).to have_content I18n.t("summary.label.activity.organisation")
    expect(page).to have_content activity_presenter.organisation.name

    expect(page).to have_content I18n.t("summary.label.activity.identifier")
    expect(page).to have_content activity_presenter.identifier

    expect(page).to have_content I18n.t("summary.label.activity.title", level: activity_presenter.level).capitalize
    expect(page).to have_content activity_presenter.title

    expect(page).to have_content I18n.t("summary.label.activity.description")
    expect(page).to have_content activity_presenter.description

    expect(page).to have_content I18n.t("summary.label.activity.sector", level: activity_presenter.level)
    expect(page).to have_content activity_presenter.sector

    expect(page).to have_content I18n.t("summary.label.activity.status")
    expect(page).to have_content activity_presenter.status

    expect(page).to have_content I18n.t("summary.label.activity.planned_start_date")
    expect(page).to have_content activity_presenter.planned_start_date

    expect(page).to have_content I18n.t("summary.label.activity.planned_end_date")
    expect(page).to have_content activity_presenter.planned_end_date

    expect(page).to have_content I18n.t("summary.label.activity.actual_start_date")
    expect(page).to have_content activity_presenter.actual_start_date

    expect(page).to have_content I18n.t("summary.label.activity.actual_end_date")
    expect(page).to have_content activity_presenter.actual_end_date

    expect(page).to have_content I18n.t("summary.label.activity.recipient_region")
    expect(page).to have_content activity_presenter.recipient_region

    expect(page).to have_content I18n.t("summary.label.activity.flow")
    expect(page).to have_content activity_presenter.flow

    expect(page).to have_content I18n.t("summary.label.activity.aid_type")
    expect(page).to have_content activity_presenter.aid_type
  end
end
