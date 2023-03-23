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

      context "when clicking on the delete button" do
        before do
          find("details").click

          click_on "Delete this activity"
        end

        it "starts the activity deletion journey" do
          # breadcrumbs
          expect(page).to have_link("Home")
          expect(page).to have_link(activity.parent.title)
          expect(page).to have_link("Untitled activity")

          # view
          expect(page).to have_content("Deleting activity #{activity.roda_identifier}")
          expect(page).to have_content("Are you sure you want to delete this activity?")
          expect(page).to have_content("all financial data and associated child activities will also be deleted")
          expect(page).to have_content("you may need to inform the partner organisation separately")
          expect(page).to have_content("linked activities will be unlinked but they will not be deleted")
          expect(page).to have_button("Confirm")
          expect(page).to have_link("Cancel")
        end

        context "when cancelling deletion" do
          it "returns the user to the activity page" do
            click_on "Cancel"

            expect(page).to have_selector("details", text: "This activity has no title. Can we delete it?")
          end
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
