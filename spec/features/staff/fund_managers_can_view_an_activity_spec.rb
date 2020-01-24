RSpec.feature "Fund managers can view an activity" do
  let(:organisation) { create(:organisation) }

  context "when the user is not logged in" do
    scenario "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_activity_path(organisation, create(:activity, organisation: organisation))
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: build_stubbed(:fund_manager, organisation: organisation)) }

    scenario "allows the activity to be viewed" do
      existing_activity = create(:activity, organisation: organisation)

      visit organisation_path(organisation)
      click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)

      click_on(existing_activity.title)

      expect(page).to have_content(existing_activity.title)
      expect(page).to have_content(existing_activity.organisation.name)
    end

    scenario "can go back to the previous page" do
      visit organisation_activity_path(organisation, create(:activity, organisation: organisation))

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_path(organisation.id))
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner, organisation: organisation)) }

    scenario "the activity cannot be viewed" do
      existing_activity = create(:activity, organisation: organisation)

      visit organisation_path(organisation)

      expect(page).not_to have_content(I18n.t("page_content.organisation.activities"))
      expect(page).not_to have_content(existing_activity.title)
    end
  end
end
