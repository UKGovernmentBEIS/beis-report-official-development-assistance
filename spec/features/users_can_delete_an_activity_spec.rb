RSpec.feature "Users can delete an activity" do
  before do
    authenticate!(user: user)

    visit organisation_activity_path(activity.organisation, activity)

    expect(page).to have_content(activity.roda_identifier)
  end

  after { logout }

  context "when logged in as a BEIS user" do
    let(:user) { create(:beis_user) }

    context "and viewing an activity with a title" do
      let(:activity) { create(:programme_activity) }

      it "doesn't show anything about deletion" do
        expect(page).not_to have_selector("details", text: "This activity has no title. Can we delete it?")
      end
    end

    context "and viewing an untitled activity" do
      let(:activity) { create(:programme_activity, title: nil, form_state: "identifier") }

      it "tells the user they can delete it" do
        expect(page).to have_selector("details", text: "This activity has no title. Can we delete it?")

        details_element = find("details")

        details_element.click

        within details_element do
          expect(page).to have_content("You can delete this activity as it has no title.")
          expect(page).to have_link("Delete this activity")
        end
      end
    end
  end

  context "when logged in as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }

    context "and viewing an activity with a title" do
      let(:activity) { create(:programme_activity, extending_organisation: user.organisation) }

      it "doesn't show anything about deletion" do
        expect(page).not_to have_selector("details", text: "This activity has no title. Can we delete it?")
      end
    end

    context "and viewing an untitled activity" do
      let(:activity) { create(:programme_activity, extending_organisation: user.organisation, title: nil, form_state: "identifier") }

      it "tells the user BEIS can delete it" do
        expect(page).to have_selector("details", text: "This activity has no title. Can we delete it?")

        details_element = find("details")

        details_element.click

        within details_element do
          expect(page).to have_content("Only BEIS can delete this activity.")
          expect(page).to have_link("submit a support request (opens in new tab)")
        end
      end
    end
  end
end
