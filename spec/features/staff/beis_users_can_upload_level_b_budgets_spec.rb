RSpec.feature "BEIS users can upload Level B budgets" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  before do
    visit new_level_b_budgets_upload_path
  end

  scenario "viewing the page for downloading or uploading a CSV template" do
    expect(page).to have_content(t("page_title.budget.upload_level_b"))
  end
end
