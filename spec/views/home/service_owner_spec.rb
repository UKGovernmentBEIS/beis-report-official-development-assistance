RSpec.describe "staff/home/service_owner" do
  before do
    assign(:current_user, build(:beis_user))
    organisation = build(:partner_organisation, name: "Partner Org 1")
    assign(:partner_organisations, [organisation, build(:partner_organisation)])

    stub_template "staff/shared/reports/_partner_organisations_table" => "table of partner organisations"
    stub_template "staff/searches/_form" => "search form"

    allow(view).to receive(:organisation_path).and_return("/organisations/id")
    allow(view).to receive(:organisation_activities_path).and_return("/organisation/id/activities")
    allow(view).to receive(:exports_organisation_path).and_return("/exports/organisation/id")
    allow(view).to receive(:organisation_reports_path).and_return("/organisation/id/reports")

    render
  end

  it "has links to a partner organisation's details, activities, exports and reports" do
    expect(rendered).to have_link("Partner Org 1", href: "/organisations/id")
    expect(rendered).to have_link(t("table.cell.organisations.view_activities"), href: "/organisation/id/activities")
    expect(rendered).to have_link(t("table.cell.organisations.view_exports"), href: "/exports/organisation/id")
    expect(rendered).to have_link(t("table.cell.organisations.view_reports"), href: "/organisation/id/reports")
  end
end
