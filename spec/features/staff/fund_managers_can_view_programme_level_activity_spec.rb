RSpec.feature "Fund managers can view programe level activites" do
  let(:programme) { create(:activity, level: :programme) }
  let(:fund_activity) { create(:activity, level: :fund) }

  context "when signed in" do
    before do
      authenticate!(user: create(:fund_manager))
      fund_activity.activities << programme
    end

    it "shows the programme level activity" do
      visit organisation_activity_path(programme.organisation, programme)
      expect(page).to have_content programme.title
    end

    it "does not show a create programme button" do
      visit organisation_activity_path(programme.organisation, programme)

      expect(page).not_to have_button I18n.t("page_content.organisation.button.create_programme")
    end

    it "shows the choose extending organisation button" do
      visit organisation_activity_path(programme.organisation, programme)
      expect(page).to have_link I18n.t("page_content.organisation.button.choose_extending_organisation")
    end

    it "shows the create transaction button" do
      visit organisation_activity_path(programme.organisation, programme)

      expect(page).to have_link I18n.t("page_content.transactions.button.create")
    end
  end

  context "when signed out" do
    it "redirects to the root path" do
      visit organisation_activity_path(programme.organisation, programme)
      expect(current_path).to eq root_path
    end
  end
end
