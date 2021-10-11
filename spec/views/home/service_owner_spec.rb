RSpec.describe "staff/home/service_owner" do
  before do
    assign(:current_user, build(:beis_user))
    assign(:delivery_partner_organisations, build_list(:delivery_partner_organisation, 2))

    stub_template "staff/shared/reports/_delivery_partners_organisations_table" => "table of delivery partners"
    stub_template "staff/searches/_form" => "search form"

    allow(view).to receive(:organisation_path).and_return("/organisations/id")
    allow(view).to receive(:organisation_activities_path).and_return("/organisation/id/activities")
    allow(view).to receive(:exports_organisation_path).and_return("/exports/organisation/id")
    allow(view).to receive(:organisation_reports_path).and_return("/organisation/id/reports")

    render
  end

  it "has links to a delivery partners details, activities, exports and reports" do
    expect(rendered).to have_link("View details", href: "/organisations/id")
    expect(rendered).to have_link("View activities", href: "/organisation/id/activities")
    expect(rendered).to have_link("View exports", href: "/exports/organisation/id")
    expect(rendered).to have_link("View reports", href: "/organisation/id/reports")
  end
end
