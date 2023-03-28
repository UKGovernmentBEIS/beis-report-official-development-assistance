RSpec.feature "Users can view programme level activities" do
  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    let(:programme) { create(:programme_activity, organisation: user.organisation) }

    before { authenticate!(user: user) }
    after { logout }

    it "shows the programme level activity" do
      visit organisation_activity_path(programme.organisation, programme)

      page_displays_an_activity(activity_presenter: ActivityPresenter.new(programme))
    end

    it "does not show a link to download as XML" do
      visit organisation_activity_path(programme.organisation, programme)

      expect(page).to_not have_content t("default.button.download_as_xml")
    end
  end

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:partner_organisation_user) }
    let(:programme) { create(:programme_activity, extending_organisation: user.organisation) }
    let(:project) { create(:project_activity, parent: programme, organisation: user.organisation) }

    before { authenticate!(user: user) }
    after { logout }

    it "shows the programme level activity" do
      visit organisation_activity_details_path(user.organisation, project)

      within(".activity-details") do
        click_on programme.title
      end

      page_displays_an_activity(activity_presenter: ActivityPresenter.new(programme))
    end

    it "does not show a link to download as XML" do
      visit organisation_activity_details_path(user.organisation, programme)

      expect(page).to_not have_content t("default.button.download_as_xml")
    end
  end
end
