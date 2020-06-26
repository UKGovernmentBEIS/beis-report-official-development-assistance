RSpec.feature "Users can view programme level activites" do
  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    it "shows the programme level activity" do
      authenticate!(user: user)

      fund_activity = create(:fund_activity, organisation: user.organisation)
      programme_activity = create(:programme_activity,
        organisation: user.organisation,
        parent: fund_activity)

      visit organisation_path(user.organisation)

      expect(page).to have_content I18n.t("page_content.organisation.programmes")

      click_on programme_activity.title

      page_displays_an_activity(activity_presenter: ActivityPresenter.new(programme_activity))
    end
  end

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }

    it "shows the programme level activity" do
      authenticate!(user: user)

      fund_activity = create(:fund_activity, organisation: user.organisation)
      programme_activity = create(:programme_activity,
        organisation: user.organisation,
        parent: fund_activity,
        extending_organisation: user.organisation)

      visit organisation_path(user.organisation)
      expect(page).not_to have_content I18n.t("page_content.organisation.funds")
      expect(page).to have_content I18n.t("page_content.organisation.programmes")
      click_on programme_activity.title

      page_displays_an_activity(activity_presenter: ActivityPresenter.new(programme_activity))
    end
  end
end
