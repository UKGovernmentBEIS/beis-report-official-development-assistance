RSpec.feature "Users can export spending breakdown" do
  context "as a BEIS user" do
    before do
      authenticate! user: create(:beis_user, email: "beis@example.com")
    end

    scenario "they can request a spending breakdown export for all organisations" do
      visit exports_path
      click_link "Request Spending breakdown for Newton Fund"

      export_in_progress_msg =
        "The requested spending breakdown for Newton Fund is being prepared. " \
        "We will send a download link to beis@example.com when it is ready."

      expect(page).to have_content(export_in_progress_msg)
    end

    scenario "they can download the spending breakdown export for a single organisation" do
      delivery_partner_organisation = create(:delivery_partner_organisation)

      visit exports_path
      click_link delivery_partner_organisation.name
      click_link "Download Newton Fund spending breakdown"

      expect(page.status_code).to eq 200

      headers = CSV.parse(page.body.delete_prefix("\ufeff"), headers: true).headers
      expect(headers).to include(t("activerecord.attributes.activity.roda_identifier"))
    end
  end

  context "as a delivery partner user" do
    let(:organisation) { create(:delivery_partner_organisation) }

    before do
      authenticate! user: create(:delivery_partner_user, organisation: organisation)
    end

    scenario "they cannot download spending breakdown for all organisations" do
      visit exports_path
      expect(page.status_code).to eq 401
    end

    scenario "they cannot download spending breakdown for an organisation they are not associated with" do
      other_organisation = create(:delivery_partner_organisation)
      visit spending_breakdown_exports_organisation_path(other_organisation)

      expect(page.status_code).to eq 401
    end

    scenario "they can download spending breakdown for an organissation they are associated with" do
      visit exports_organisation_path(organisation)
      click_link "Download Newton Fund spending breakdown"

      expect(page.status_code).to eq 200

      headers = CSV.parse(page.body.delete_prefix("\ufeff"), headers: true).headers
      expect(headers).to include(t("activerecord.attributes.activity.roda_identifier"))
    end
  end
end
