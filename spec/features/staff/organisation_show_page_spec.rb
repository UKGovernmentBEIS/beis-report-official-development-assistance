feature "Organisation show page" do
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let(:beis_user) { create(:beis_user) }

  let(:fund) { create(:fund_activity, organisation: beis_user.organisation) }
  let!(:incomplete_fund) { create(:fund_activity, :at_purpose_step, organisation: beis_user.organisation) }
  let(:programme) do
    create(:programme_activity,
      parent: fund,
      organisation: beis_user.organisation,
      extending_organisation: delivery_partner_user.organisation)
  end
  let!(:incomplete_programme) { create(:programme_activity, :at_purpose_step, extending_organisation: delivery_partner_user.organisation) }
  let!(:project) { create(:project_activity, parent: programme, organisation: delivery_partner_user.organisation, created_at: Date.today) }
  let!(:incomplete_project) { create(:project_activity, :at_geography_step, parent: programme, organisation: delivery_partner_user.organisation, created_at: Date.yesterday) }
  let!(:third_party_project) { create(:third_party_project_activity, parent: project, organisation: delivery_partner_user.organisation) }
  let!(:incomplete_third_party_project) { create(:third_party_project_activity, :at_region_step, parent: project, organisation: delivery_partner_user.organisation) }
  let!(:another_programme) { create(:programme_activity) }
  let!(:another_project) { create(:project_activity) }
  let!(:submission) { create(:submission, organisation: delivery_partner_user.organisation) }
  let!(:other_submission) { create(:submission, organisation: create(:organisation)) }

  context "when signed in as a BEIS user" do
    context "when viewing the BEIS organisation" do
      before do
        authenticate!(user: beis_user)
        visit organisation_path(beis_user.organisation)
      end

      scenario "they see the organisation details" do
        expect(page).to have_content beis_user.organisation.name
        expect(page).to have_content beis_user.organisation.iati_reference
      end

      scenario "they see a edit details button" do
        expect(page).to have_link I18n.t("page_content.organisation.button.edit_details"), href: edit_organisation_path(beis_user.organisation)
      end

      scenario "they see all submissions" do
        expect(page).to have_content "Submissions"

        within(".submissions") do
          expect(page).to have_content submission.organisation.name
          expect(page).to have_content submission.description
          expect(page).to have_content other_submission.organisation.name
          expect(page).to have_content other_submission.description
        end
      end
    end

    context "when viewing a delivery partners organisation" do
      scenario "they do not see funds or the create fund button" do
        visit organisation_path(delivery_partner_user.organisation)

        expect(page).not_to have_button I18n.t("page_content.organisation.button.create_activity")
        expect(page).not_to have_content "Funds"
      end
    end
  end

  context "when signed in as a delivery partner user" do
    before do
      authenticate!(user: delivery_partner_user)
      visit organisation_path(delivery_partner_user.organisation)
    end

    scenario "they do not see a list of funds" do
      expect(page).not_to have_table "Funds"
    end

    scenario "they do not see a create fund button" do
      expect(page).not_to have_button I18n.t("page_content.organisation.button.create_activity")
    end

    scenario "they do not see the edit detials button" do
      expect(page).not_to have_link I18n.t("page_content.organisation.button.edit_details"), href: edit_organisation_path(delivery_partner_user.organisation)
    end

    scenario "they see their own submissions" do
      expect(page).to have_content "Submissions"
      within(".submissions") do
        expect(page).to have_content submission.organisation.name
        expect(page).to have_content submission.description
      end
    end

    scenario "they do not see submissions belonging to other organisations" do
      within(".submissions") do
        expect(page).to_not have_content other_submission.organisation.name
        expect(page).to_not have_content other_submission.description
      end
    end
  end
end
