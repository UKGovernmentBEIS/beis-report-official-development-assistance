RSpec.feature "Fund managers can view fund level activities" do
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
      authenticate!(user: create(:fund_manager))
    end

    scenario "the user will see activities on the organisation show page" do
      activity = create(:activity, organisation: organisation)
      visit organisations_path
      click_link organisation.name

      expect(page).to have_content(I18n.t("page_content.organisation.funds"))
      expect(page).to have_content activity.title
    end

    context "when the activity is partially complete and doesn't have a title" do
      scenario "it to show a meaningful link to the activity" do
        activity = create(:activity, :at_identifier_step, organisation: organisation, title: nil)

        visit organisation_path(organisation)

        expect(page).to have_content("Untitled (#{activity.id})")
      end
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
      authenticate!(user: create(:delivery_partner, organisation: organisation))
    end

    scenario "the user will not see them on the show page for their organisation" do
      activity = create(:activity, organisation: organisation)

      visit organisations_path
      click_link organisation.name

      expect(page).not_to have_content(I18n.t("page_content.organisation.funds"))
      expect(page).not_to have_content activity.title
    end
  end
end
