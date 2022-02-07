RSpec.describe Staff::ReportsController do
  let(:delivery_partner_user) { create(:delivery_partner_user) }
  let(:organisation) { delivery_partner_user.organisation }

  before do
    allow(subject).to receive(:current_user).and_return(delivery_partner_user)
  end

  describe "#index" do
    it "redirects to show the user's organisation's reports" do
      expect(get(:index)).to redirect_to(organisation_reports_path(organisation_id: organisation.id))
    end
  end

  describe "#show" do
    it "returns the report file successfully" do
      report = create(:report, organisation: delivery_partner_user.organisation)
      export_double = double(Export::Report, filename: "export.csv", headers: [], rows: [])
      allow(Export::Report).to receive(:new).with(report: report).and_return(export_double)

      get :show, params: {id: report.id, format: :csv}

      expect(export_double).to have_received(:filename).once
      expect(Export::Report).to have_received(:new).once
      expect(response.header["Content-Disposition"]).to include("filename=export.csv")
    end

    it "returns the legacy report file successfully" do
      report = create(:report, organisation: delivery_partner_user.organisation)
      export_double = double(Report::Export, filename: "legacy_export.csv", headers: [], rows: [])
      allow(Report::Export).to receive(:new).with(report: report).and_return(export_double)

      get :show, params: {id: report.id, format: :csv, legacy: true}

      expect(export_double).to have_received(:filename).once
      expect(Report::Export).to have_received(:new).once
      expect(response.header["Content-Disposition"]).to include("filename=legacy_export.csv")
    end
  end
end
