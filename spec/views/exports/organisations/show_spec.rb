RSpec.describe "staff/exports/organisations/show" do
  let(:organisation) { build(:partner_organisation, id: SecureRandom.uuid) }
  let(:xml_downloads) do
    [
      double("Iati::XmlDownload", title: "XML Download 1", path: "http://example.com/1"),
      double("Iati::XmlDownload", title: "XML Download 2", path: "http://example.com/2")
    ]
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:policy) do |record|
        Pundit.policy(user, record)
      end
      allow(view).to receive(:current_user).and_return(user)
    end

    assign(:xml_downloads, xml_downloads)
    assign(:organisation, organisation)

    render
  end

  context "when the current user is a BEIS user" do
    let(:user) { build(:beis_user) }

    it "shows the link to download all actuals" do
      expect(rendered).to have_export_row(report: "All actuals", path: actuals_exports_organisation_path(organisation, format: "csv"))
    end

    it "shows the links to download the XML" do
      expect(rendered).to have_export_row(report: "XML Download 1", path: "http://example.com/1")
      expect(rendered).to have_export_row(report: "XML Download 2", path: "http://example.com/2")
    end

    it "shows the links to download the external income" do
      expect(rendered).to have_export_row(report: "Newton Fund external income", path: external_income_exports_organisation_path(organisation, fund_id: 1, format: "csv"))
      expect(rendered).to have_export_row(report: "Global Challenges Research Fund external income", path: external_income_exports_organisation_path(organisation, fund_id: 2, format: "csv"))
    end

    it "shows the links to download the spending breakdown" do
      expect(rendered).to have_export_row(report: "Newton Fund spending breakdown", path: spending_breakdown_exports_organisation_path(organisation, fund_id: 1, format: "csv"))
      expect(rendered).to have_export_row(report: "Global Challenges Research Fund spending breakdown", path: spending_breakdown_exports_organisation_path(organisation, fund_id: 2, format: "csv"))
    end
  end

  context "when the current user is a partner organisation user" do
    let(:user) { build(:partner_organisation_user, organisation: organisation) }

    it "does not show the link to download all actuals" do
      expect(rendered).to_not have_export_row(report: "All actuals", path: actuals_exports_organisation_path(organisation, format: "csv"))
    end

    it "does not show the links to download the XML" do
      expect(rendered).to_not have_export_row(report: "XML Download 1", path: "http://example.com/1")
      expect(rendered).to_not have_export_row(report: "XML Download 2", path: "http://example.com/2")
    end

    it "shows the links to download the external income" do
      expect(rendered).to have_export_row(report: "Newton Fund external income", path: external_income_exports_organisation_path(organisation, fund_id: 1, format: "csv"))
      expect(rendered).to have_export_row(report: "Global Challenges Research Fund external income", path: external_income_exports_organisation_path(organisation, fund_id: 2, format: "csv"))
    end
  end

  RSpec::Matchers.define :have_export_row do |args|
    match do |actual|
      export_row = export_row(actual, args)

      expect(export_row).to_not be_nil
      expect(export_row).to have_content(args[:report])
      expect(export_row).to have_link(href: args[:path])
    end

    def export_row(actual, args)
      body = Capybara.string(actual)
      rows = body.all(".govuk-table__row")
      rows.find { |r| r.has_css?("td.govuk-table__cell", text: args[:report]) }
    end
  end
end
