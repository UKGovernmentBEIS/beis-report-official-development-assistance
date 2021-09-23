RSpec.feature "BEIS users can export spending breakdown" do
  context "as a BEIS user" do
    before do
      authenticate! user: create(:beis_user)
    end

    scenario "they can download the spending breakdown export" do
      visit exports_path
      click_link "Download Spending breakdown for Newton Fund"

      expect(page.status_code).to eq 200

      headers = CSV.parse(page.body.delete_prefix("\ufeff"), headers: true).headers
      expect(headers).to include(t("activerecord.attributes.activity.roda_identifier"))
    end
  end
end
