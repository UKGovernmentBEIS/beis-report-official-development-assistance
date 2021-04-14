RSpec.feature "Users can view third-party project level activities" do
  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "can view a third-party project" do
      project = create(:project_activity, organisation: user.organisation)
      third_party_project = create(:third_party_project_activity, parent: project, organisation: user.organisation)

      visit organisation_activity_path(third_party_project.organisation, third_party_project)

      expect(page).to have_content third_party_project.title
    end

    scenario "cannot download a project as XML" do
      third_party_project = create(:third_party_project_activity)

      visit organisation_activity_path(third_party_project.organisation, third_party_project)

      expect(page).to_not have_content t("default.button.download_as_xml")
    end

    scenario "can view and add budgets and transactions on a third-party project" do
      third_party_project = create(:third_party_project_activity, organisation: user.organisation)
      budget = create(:budget, parent_activity: third_party_project)
      transaction = create(:transaction, parent_activity: third_party_project)
      _report = create(:report, state: :active, organisation: user.organisation, fund: third_party_project.associated_fund)

      visit organisation_activity_path(third_party_project.organisation, third_party_project)

      expect(page).to have_content(budget.value)
      expect(page).to have_content(transaction.value)
      expect(page).to have_content(t("page_content.budgets.button.create"))
      expect(page).to have_content(t("page_content.transactions.button.create"))
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "can view a third-party project but not create one" do
      third_party_project = create(:third_party_project_activity)

      visit organisation_activity_path(third_party_project.organisation, third_party_project)

      expect(page).to have_content third_party_project.title
      expect(page).to have_no_button t("action.activity.add_child")
    end

    scenario "can download a third-party project as XML" do
      third_party_project = create(:third_party_project_activity, transparency_identifier: "GB-GOV-13-PROJECT")

      visit organisation_activity_path(third_party_project.organisation, third_party_project)

      expect(page).to have_content t("default.button.download_as_xml")

      click_on t("default.button.download_as_xml")

      expect(page.response_headers["Content-Type"]).to include("application/xml")

      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/^attachment/)
      expect(header).to match(/filename=\"#{third_party_project.transparency_identifier}.xml\"$/)
    end
  end
end
