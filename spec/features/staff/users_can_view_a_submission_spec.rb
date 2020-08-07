RSpec.feature "Users can view a submission" do
  let(:beis_user) { create(:beis_user) }
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let!(:submission) { create(:submission, organisation: delivery_partner_user.organisation, deadline: nil, description: "Legacy Submission") }

  context "as a BEIS user" do
    before do
      authenticate!(user: beis_user)
    end

    scenario "can view a submission belonging to any delivery partner" do
      visit organisation_path(beis_user.organisation)

      within "##{submission.id}" do
        click_on I18n.t("default.link.show")
      end

      expect(page).to have_content submission.description
    end

    scenario "can download a CSV of the submission" do
      visit organisation_path(beis_user.organisation)

      within "##{submission.id}" do
        click_on I18n.t("default.link.show")
      end

      click_on I18n.t("default.button.download_as_csv")

      expect(page.response_headers["Content-Type"]).to include("text/csv")

      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/#{submission.description}/)
    end
  end

  context "as a delivery partner user" do
    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "can view their own submission" do
      visit organisation_path(delivery_partner_user.organisation)

      within "##{submission.id}" do
        click_on I18n.t("default.link.show")
      end

      expect(page).to have_content submission.description
    end

    scenario "cannot view a submission belonging to another delivery partner" do
      another_submission = create(:submission, organisation: create(:organisation))

      visit organisation_path(delivery_partner_user.organisation)

      expect(page).to_not have_content another_submission.description
    end

    scenario "can download a CSV of their own submission" do
      visit organisation_path(delivery_partner_user.organisation)

      within "##{submission.id}" do
        click_on I18n.t("default.link.show")
      end

      click_on I18n.t("default.button.download_as_csv")

      expect(page.response_headers["Content-Type"]).to include("text/csv")

      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/#{submission.description}/)
    end
  end
end
