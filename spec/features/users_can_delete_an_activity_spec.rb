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

        context "when confirming deletion" do
          let!(:budget) { create(:budget, parent_activity: activity) }
          let!(:actual) { create(:actual, parent_activity: activity) }
          let!(:refund) { create(:refund, parent_activity: activity) }
          let!(:adjustment) { create(:adjustment, parent_activity: activity) }

          context "at programme level" do
            let!(:child_activity) { create(:project_activity, parent: activity) }
            let!(:grandchild_activity) { create(:third_party_project_activity, parent: child_activity) }

            it "deletes the activity, its associations and children, and confirms the deletion" do
              click_on "Confirm"

              expect_activity_to_be_deleted(level: :programme)
            end
          end

          context "below programme level" do
            let(:activity) { create(:project_activity, title: nil, form_state: "purpose") }
            let!(:child_activity) { create(:third_party_project_activity, parent: activity) }

            it "deletes the activity, its associations and children, and confirms the deletion" do
              click_on "Confirm"

              expect_activity_to_be_deleted(level: :project)
            end
          end

          context "on an activity that has a linked activity, and so do its descendants" do
            let(:partner_organisation) { create(:partner_organisation) }

            let(:activity) {
              create(
                :programme_activity,
                :ispf_funded,
                is_oda: true,
                extending_organisation: partner_organisation,
                title: nil,
                form_state: "identifier"
              )
            }

            let!(:linked_activity) {
              create(
                :programme_activity,
                :ispf_funded,
                is_oda: false,
                extending_organisation: partner_organisation,
                linked_activity: activity
              )
            }

            let!(:child_activity) {
              create(
                :project_activity,
                :ispf_funded,
                parent: activity,
                is_oda: true,
                extending_organisation: partner_organisation
              )
            }

            let!(:child_linked_activity) {
              create(
                :project_activity,
                :ispf_funded,
                parent: linked_activity,
                is_oda: false,
                extending_organisation: partner_organisation,
                linked_activity: child_activity
              )
            }

            let!(:grandchild_activity) {
              create(
                :third_party_project_activity,
                :ispf_funded,
                parent: child_activity,
                is_oda: true,
                extending_organisation: partner_organisation
              )
            }

            let!(:grandchild_linked_activity) {
              create(
                :third_party_project_activity,
                :ispf_funded,
                parent: child_linked_activity,
                is_oda: false,
                extending_organisation: partner_organisation,
                linked_activity: grandchild_activity
              )
            }

            it "removes the linked activity ID from the remaining activities" do
              expect(linked_activity.linked_activity_id).to eq(activity.id)
              expect(child_linked_activity.linked_activity_id).to eq(child_activity.id)
              expect(grandchild_linked_activity.linked_activity_id).to eq(grandchild_activity.id)

              click_on "Confirm"

              expect(linked_activity.reload.linked_activity_id).to be_nil
              expect(child_linked_activity.reload.linked_activity_id).to be_nil
              expect(grandchild_linked_activity.reload.linked_activity_id).to be_nil
            end
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

  def expect_activity_to_be_deleted(level:)
    expect(page).to have_content("Success")
    expect(page).to have_content("Activities deleted.")
    expect(page).to have_content("#{activity.roda_identifier} and its child activities have been deleted.")

    expect(Activity.find_by(id: activity.id)).to be_nil
    expect(Budget.find_by(id: budget.id)).to be_nil
    expect(Actual.find_by(id: actual.id)).to be_nil
    expect(Refund.find_by(id: refund.id)).to be_nil
    expect(Adjustment.find_by(id: adjustment.id)).to be_nil
    expect(Activity.find_by(id: child_activity.id)).to be_nil

    expect(Activity.find_by(id: grandchild_activity.id)).to be_nil if level == :programme
  end
end
