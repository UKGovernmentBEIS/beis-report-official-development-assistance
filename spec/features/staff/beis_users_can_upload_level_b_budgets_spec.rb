RSpec.feature "BEIS users can upload Level B budgets" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  before do
    visit new_level_b_budgets_upload_path
  end

  scenario "viewing the page for downloading or uploading a CSV template" do
    expect(page).to have_content(t("page_title.budget.upload_level_b"))
  end

  scenario "downloading the CSV template" do
    click_link t("action.budget.bulk_download.button")

    csv_data = page.body.delete_prefix("\uFEFF")
    rows = CSV.parse(csv_data, headers: false).first

    expect(rows).to match_array([
      "Type",
      "Financial year",
      "Budget amount",
      "Providing organisation",
      "Providing organisation type",
      "IATI reference",
      "Activity RODA ID",
      "Fund RODA ID",
      "Partner organisation name"
    ])
  end
end
