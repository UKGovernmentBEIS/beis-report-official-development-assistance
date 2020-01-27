RSpec.feature "Fund managers can view activities on an organisation page" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  let(:organisation) { create(:organisation) }

  context "when the user is a fund_manager" do
    before do
      authenticate!(user: create(:fund_manager, organisations: []))
    end

    scenario "the user will see them on the organisation show page" do
      activity = create(:activity, organisation: organisation)
      visit organisations_path
      click_link organisation.name

      expect(page).to have_content(I18n.t("page_content.organisation.activities"))
      expect(page).to have_content activity.title
    end

    scenario "can go back to the previous page" do
      activity = create(:activity, organisation: organisation)
      visit organisation_activity_path(organisation, activity)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_path(organisation))
    end
  end

  context "when the user is a delivery_partner" do
    before do
      authenticate!(user: create(:delivery_partner, organisations: [organisation]))
    end

    scenario "the user will not see them on the show page for their organisation" do
      activity = create(:activity, organisation: organisation)

      visit organisations_path
      click_link organisation.name

      expect(page).not_to have_content(I18n.t("page_content.organisation.activities"))
      expect(page).not_to have_content activity.title
    end
  end
end
