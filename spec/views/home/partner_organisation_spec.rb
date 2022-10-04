RSpec.describe "staff/home/partner_organisation" do
  context "when there are no active reports" do
    before do
      assign(:current_user, build(:partner_organisation_user))
      assign(:grouped_activities, [])
      assign(:reports, nil)

      allow(view).to receive(:organisation_reports_path).and_return("/reports/id")

      stub_template "staff/shared/reports/_table" => "table of reports"
      stub_template "staff/shared/activities/tree_view/_table_tabbed" => "tree view"
      stub_template "staff/searches/_form" => "search form"

      render
    end

    it "renders a special message" do
      expect(view).not_to render_template "staff/shared/reports/_table"
      expect(view).to render_template "staff/home/_empty_report_status"
    end
  end

  context "when there are active reports" do
    before do
      assign(:current_user, build(:partner_organisation_user))
      assign(:grouped_activities, [])
      assign(:reports, build_list(:report, 2, :active))

      allow(view).to receive(:organisation_reports_path).and_return("/reports/id")

      stub_template "staff/shared/reports/_table" => "table of reports"
      stub_template "staff/shared/activities/tree_view/_table_tabbed" => "tree view"
      stub_template "staff/searches/_form" => "search form"

      render
    end

    it "renders a table of the reports" do
      expect(view).to render_template "staff/shared/reports/_table"
      expect(view).not_to render_template "staff/home/_empty_report_status"
    end
  end
end
