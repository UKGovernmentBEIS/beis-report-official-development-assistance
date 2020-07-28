feature "Organisation show page" do
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let(:beis_user) { create(:beis_user) }

  context "when signed in as a BEIS user" do
    context "when viewing the BEIS organisation" do
      before do
        authenticate!(user: beis_user)
      end

      scenario "they see the organisation details" do
        visit organisation_path(beis_user.organisation)

        expect(page).to have_content beis_user.organisation.name
        expect(page).to have_content beis_user.organisation.iati_reference
      end

      scenario "they see a edit details button" do
        visit organisation_path(beis_user.organisation)

        expect(page).to have_link I18n.t("page_content.organisation.button.edit_details"), href: edit_organisation_path(beis_user.organisation)
      end

      scenario "they see all submissions" do
        submission = create(:submission, organisation: delivery_partner_user.organisation)
        other_submission = create(:submission, organisation: create(:organisation))

        visit organisation_path(beis_user.organisation)

        expect(page).to have_content "Submissions"

        within(".submissions") do
          expect(page).to have_content submission.organisation.name
          expect(page).to have_content submission.description
          expect(page).to have_content other_submission.organisation.name
          expect(page).to have_content other_submission.description
        end
      end

      context "when viewing a delivery partners organisation" do
        scenario "they see a download xml button for project activties" do
          delivery_partner_organisation = create(:delivery_partner_organisation)
          _project = create(:project_activity, organisation: delivery_partner_organisation)

          visit organisation_path(delivery_partner_organisation)

          expect(page).to have_link I18n.t("page_content.organisation.download.title"),
            href: organisation_path(delivery_partner_organisation, format: :xml, level: :project)
        end

        scenario "they see a download xml button for third-party project activities" do
          delivery_partner_organisation = create(:delivery_partner_organisation)
          _third_party_project = create(:third_party_project_activity, organisation: delivery_partner_organisation)

          visit organisation_path(delivery_partner_organisation)

          expect(page).to have_link I18n.t("page_content.organisation.download.title"),
            href: organisation_path(delivery_partner_organisation, format: :xml, level: :third_party_project)
        end
      end
    end
  end

  context "when signed in as a delivery partner user" do
    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "they do not see the edit detials button" do
      visit organisation_path(delivery_partner_user.organisation)

      expect(page).not_to have_link I18n.t("page_content.organisation.button.edit_details"), href: edit_organisation_path(delivery_partner_user.organisation)
    end

    scenario "they see their own submissions" do
      submission = create(:submission, organisation: delivery_partner_user.organisation)

      visit organisation_path(delivery_partner_user.organisation)

      expect(page).to have_content "Submissions"
      within(".submissions") do
        expect(page).to have_content submission.organisation.name
        expect(page).to have_content submission.description
      end
    end

    scenario "they do not see submissions belonging to other organisations" do
      _submission = create(:submission, organisation: delivery_partner_user.organisation)
      other_submission = create(:submission, organisation: create(:organisation))

      visit organisation_path(delivery_partner_user.organisation)

      within(".submissions") do
        expect(page).to_not have_content other_submission.organisation.name
        expect(page).to_not have_content other_submission.description
      end
    end
  end
end
