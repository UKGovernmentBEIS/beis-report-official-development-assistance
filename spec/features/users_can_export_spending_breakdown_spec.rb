RSpec.feature "Users can export spending breakdown" do
  context "as a BEIS user" do
    before do
      Fund.all.each { |fund| create(:fund_activity, source_fund_code: fund.id, roda_identifier: fund.short_name) }

      authenticate! user: create(:beis_user, email: "beis@example.com")
    end
    after { logout }

    let(:upload) do
      OpenStruct.new(
        timestamped_filename: "filename-20231117173100.csv"
      )
    end
    let(:uploader) { instance_double(Export::S3Uploader, upload: upload) }

    scenario "they can request, then download a spending breakdown export for all organisations" do
      allow(Export::S3Uploader).to receive(:new).and_return(uploader)

      visit exports_path
      click_link "Request Spending breakdown for Newton Fund"

      perform_enqueued_jobs

      export_in_progress_msg =
        "The requested spending breakdown for Newton Fund is being prepared. " \
        "We will send a download link to beis@example.com when it is ready."

      expect(page).to have_content(export_in_progress_msg)

      visit exports_path
      newton_fund_id = Fund.by_short_name("NF").id

      expect(page).to have_link("Download Spending breakdown for Newton Fund", href: spending_breakdown_download_export_path(newton_fund_id))
    end

    context "when a fund already has an uploaded spending breakdown" do
      let(:newton_fund) { Fund.by_short_name("NF").activity }

      before do
        newton_fund.update!(spending_breakdown_filename: "spending_breakdown-20230130120000.csv")
      end

      scenario "they can download the existing spending breakdown as well as request a new one" do
        visit exports_path

        newton_fund_id = Fund.by_short_name("NF").id
        expect(page).to have_link("Download Spending breakdown for Newton Fund", href: spending_breakdown_download_export_path(newton_fund_id))
        expect(page).to have_content("last generated at 2023-01-30 12:00")
        expect(page).to have_link("Request new Spending breakdown for Newton Fund", href: spending_breakdown_exports_path(fund_id: newton_fund_id))
      end
    end

    scenario "they can download the spending breakdown export for a single organisation" do
      partner_organisation = create(:partner_organisation)

      visit exports_path
      click_link partner_organisation.name
      click_link "Download Newton Fund spending breakdown"

      expect(page).to have_http_status(:ok)

      headers = CSV.parse(page.body.delete_prefix("\ufeff"), headers: true).headers
      expect(headers).to include(t("activerecord.attributes.activity.roda_identifier"))
    end
  end

  context "as a partner organisation user" do
    let(:organisation) { create(:partner_organisation) }

    before do
      authenticate! user: create(:partner_organisation_user, organisation: organisation)
    end

    after { logout }

    scenario "they cannot download spending breakdown for all organisations" do
      visit exports_path
      expect(page).to have_http_status(:unauthorized)
    end

    scenario "they cannot download spending breakdown for an organisation they are not associated with" do
      other_organisation = create(:partner_organisation)
      visit spending_breakdown_exports_organisation_path(other_organisation)

      expect(page).to have_http_status(:unauthorized)
    end

    scenario "they can download spending breakdown for an organisation they are associated with" do
      visit exports_organisation_path(organisation)
      click_link "Download Newton Fund spending breakdown"

      expect(page).to have_http_status(:ok)

      headers = CSV.parse(page.body.delete_prefix("\ufeff"), headers: true).headers
      expect(headers).to include(t("activerecord.attributes.activity.roda_identifier"))
    end
  end
end
