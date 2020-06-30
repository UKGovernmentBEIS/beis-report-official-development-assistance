module ActivityHelpers
  def page_displays_an_activity(activity_presenter:)
    click_on I18n.t("tabs.activity.details")
    expect(page).to have_content activity_presenter.identifier
    expect(page).to have_content activity_presenter.title
    expect(page).to have_content activity_presenter.description
    expect(page).to have_content activity_presenter.sector
    expect(page).to have_content activity_presenter.status
    expect(page).to have_content activity_presenter.planned_start_date
    expect(page).to have_content activity_presenter.planned_end_date
    expect(page).to have_content activity_presenter.actual_start_date
    expect(page).to have_content activity_presenter.actual_end_date
    expect(page).to have_content activity_presenter.recipient_region
    expect(page).to have_content activity_presenter.flow
    expect(page).to have_content activity_presenter.aid_type
  end
end
