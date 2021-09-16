RSpec.feature "BEIS users can download exports" do
  before do
    authenticate! user: create(:beis_user)
  end

  scenario "downloading the actuals for a delivery partner" do
    delivery_partner = create(:delivery_partner_organisation)
    project = create(:project_activity, organisation: delivery_partner)
    create(:actual, parent_activity: project, financial_year: 2019, financial_quarter: 3, value: 150)

    visit exports_path
    click_link delivery_partner.name
    click_link "Download All actuals"
    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document).to match_array([
      {
        "Activity RODA Identifier" => project.roda_identifier,
        "Activity BEIS Identifier" => project.beis_identifier,
        "FQ3 2019-2020" => "150.00",
      },
    ])
  end

  scenario "downloading the external income for a delivery partner" do
    delivery_partner = create(:delivery_partner_organisation)
    project = create(:project_activity, :newton_funded, organisation: delivery_partner)
    ext_income1 = create(:external_income, activity: project, financial_year: 2019, financial_quarter: 3, amount: 120)
    ext_income2 = create(:external_income, activity: project, financial_year: 2021, financial_quarter: 1, amount: 240)

    visit exports_path
    click_link delivery_partner.name
    click_link "Newton Fund external income"
    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document.size).to eq(2)
    expect(document).to match_array([
      {
        "RODA identifier" => project.roda_identifier,
        "Delivery partner identifier" => project.delivery_partner_identifier,
        "Delivery partner organisation" => delivery_partner.name,
        "Title" => project.title,
        "Level" => "Project (level C)",
        "Providing organisation" => ext_income1.organisation.name,
        "ODA" => "Yes",
        "FQ3 2019-2020" => "120.00",
        "FQ4 2019-2020" => "0.00",
        "FQ1 2020-2021" => "0.00",
        "FQ2 2020-2021" => "0.00",
        "FQ3 2020-2021" => "0.00",
        "FQ4 2020-2021" => "0.00",
        "FQ1 2021-2022" => "0.00",
      },
      {
        "RODA identifier" => project.roda_identifier,
        "Delivery partner identifier" => project.delivery_partner_identifier,
        "Delivery partner organisation" => delivery_partner.name,
        "Title" => project.title,
        "Level" => "Project (level C)",
        "Providing organisation" => ext_income2.organisation.name,
        "ODA" => "Yes",
        "FQ3 2019-2020" => "0.00",
        "FQ4 2019-2020" => "0.00",
        "FQ1 2020-2021" => "0.00",
        "FQ2 2020-2021" => "0.00",
        "FQ3 2020-2021" => "0.00",
        "FQ4 2020-2021" => "0.00",
        "FQ1 2021-2022" => "240.00",
      },
    ])
  end

  scenario "downloading the external income for all delivery partners" do
    delivery_partner1, delivery_partner2 = create_list(:delivery_partner_organisation, 2)
    project1 = create(:project_activity, :newton_funded, organisation: delivery_partner1)
    project2 = create(:project_activity, :newton_funded, organisation: delivery_partner2)

    ext_income1 = create(:external_income, activity: project1, financial_year: 2019, financial_quarter: 3, amount: 120)
    ext_income2 = create(:external_income, activity: project2, financial_year: 2021, financial_quarter: 1, amount: 240)
    ext_income3 = create(:external_income, activity: project2, financial_year: 2021, financial_quarter: 2, amount: 100)

    visit exports_path
    click_link "Download for Newton Fund"

    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document.size).to eq(3)

    expect(document).to match_array([
      {
        "RODA identifier" => project1.roda_identifier,
        "Delivery partner identifier" => project1.delivery_partner_identifier,
        "Delivery partner organisation" => delivery_partner1.name,
        "Title" => project1.title,
        "Level" => "Project (level C)",
        "Providing organisation" => ext_income1.organisation.name,
        "ODA" => "Yes",
        "FQ3 2019-2020" => "120.00",
        "FQ4 2019-2020" => "0.00",
        "FQ1 2020-2021" => "0.00",
        "FQ2 2020-2021" => "0.00",
        "FQ3 2020-2021" => "0.00",
        "FQ4 2020-2021" => "0.00",
        "FQ1 2021-2022" => "0.00",
        "FQ2 2021-2022" => "0.00",
      },
      {
        "RODA identifier" => project2.roda_identifier,
        "Delivery partner identifier" => project2.delivery_partner_identifier,
        "Delivery partner organisation" => delivery_partner2.name,
        "Title" => project2.title,
        "Level" => "Project (level C)",
        "Providing organisation" => ext_income2.organisation.name,
        "ODA" => "Yes",
        "FQ3 2019-2020" => "0.00",
        "FQ4 2019-2020" => "0.00",
        "FQ1 2020-2021" => "0.00",
        "FQ2 2020-2021" => "0.00",
        "FQ3 2020-2021" => "0.00",
        "FQ4 2020-2021" => "0.00",
        "FQ1 2021-2022" => "240.00",
        "FQ2 2021-2022" => "0.00",
      },
      {
        "RODA identifier" => project2.roda_identifier,
        "Delivery partner identifier" => project2.delivery_partner_identifier,
        "Delivery partner organisation" => delivery_partner2.name,
        "Title" => project2.title,
        "Level" => "Project (level C)",
        "Providing organisation" => ext_income3.organisation.name,
        "ODA" => "Yes",
        "FQ3 2019-2020" => "0.00",
        "FQ4 2019-2020" => "0.00",
        "FQ1 2020-2021" => "0.00",
        "FQ2 2020-2021" => "0.00",
        "FQ3 2020-2021" => "0.00",
        "FQ4 2020-2021" => "0.00",
        "FQ1 2021-2022" => "0.00",
        "FQ2 2021-2022" => "100.00",
      },
    ])
  end
end
