RSpec.feature "BEIS users can download exports" do
  before do
    authenticate! user: create(:beis_user)
  end

  scenario "downloading the transactions for a delivery partner" do
    delivery_partner = create(:delivery_partner_organisation)
    project = create(:project_activity, organisation: delivery_partner)
    create(:transaction, parent_activity: project, financial_year: 2019, financial_quarter: 3, value: 150)

    visit exports_path
    click_link delivery_partner.name
    click_link "Download All transactions"
    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document).to match_array([
      {
        "Activity RODA Identifier" => project.roda_identifier,
        "Activity BEIS Identifier" => project.beis_identifier,
        "FQ3 2019-2020" => "150.00",
      },
    ])
  end
end
