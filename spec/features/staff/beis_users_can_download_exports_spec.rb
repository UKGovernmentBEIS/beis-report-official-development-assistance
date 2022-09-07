RSpec.feature "BEIS users can download exports" do
  before do
    authenticate! user: create(:beis_user)
  end

  scenario "downloading the actuals for a delivery partner" do
    partner_organisation = create(:delivery_partner_organisation)
    project = create(:project_activity, organisation: partner_organisation)
    create(:actual, parent_activity: project, financial_year: 2019, financial_quarter: 3, value: 150)

    visit exports_path
    click_link partner_organisation.name
    click_link "Download All actuals"
    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document).to match_array([
      {
        "Activity RODA Identifier" => project.roda_identifier,
        "Activity BEIS Identifier" => project.beis_identifier,
        "FQ3 2019-2020" => "150.00"
      }
    ])
  end

  scenario "downloading the external income for a delivery partner" do
    partner_organisation = create(:delivery_partner_organisation)
    project = create(:project_activity, :newton_funded, organisation: partner_organisation)
    ext_income1 = create(:external_income, activity: project, financial_year: 2019, financial_quarter: 3, amount: 120)
    ext_income2 = create(:external_income, activity: project, financial_year: 2021, financial_quarter: 1, amount: 240)

    visit exports_path
    click_link partner_organisation.name
    click_link "Newton Fund external income"
    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document.size).to eq(2)
    expect(document).to match_array([
      {
        "RODA identifier" => project.roda_identifier,
        "Partner organisation identifier" => project.delivery_partner_identifier,
        "Partner organisation" => partner_organisation.name,
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
        "FQ1 2021-2022" => "0.00"
      },
      {
        "RODA identifier" => project.roda_identifier,
        "Partner organisation identifier" => project.delivery_partner_identifier,
        "Partner organisation" => partner_organisation.name,
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
        "FQ1 2021-2022" => "240.00"
      }
    ])
  end

  scenario "downloading the external income for all delivery partners" do
    partner_organisation1, partner_organisation2 = create_list(:delivery_partner_organisation, 2)
    project1 = create(:project_activity, :newton_funded, organisation: partner_organisation1)
    project2 = create(:project_activity, :newton_funded, organisation: partner_organisation2)

    ext_income1 = create(:external_income, activity: project1, financial_year: 2019, financial_quarter: 3, amount: 120)
    ext_income2 = create(:external_income, activity: project2, financial_year: 2021, financial_quarter: 1, amount: 240)
    ext_income3 = create(:external_income, activity: project2, financial_year: 2021, financial_quarter: 2, amount: 100)

    visit exports_path
    click_link "Download External income for Newton Fund"

    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document.size).to eq(3)

    expect(document).to match_array([
      {
        "RODA identifier" => project1.roda_identifier,
        "Partner organisation identifier" => project1.delivery_partner_identifier,
        "Partner organisation" => partner_organisation1.name,
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
        "FQ2 2021-2022" => "0.00"
      },
      {
        "RODA identifier" => project2.roda_identifier,
        "Partner organisation identifier" => project2.delivery_partner_identifier,
        "Partner organisation" => partner_organisation2.name,
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
        "FQ2 2021-2022" => "0.00"
      },
      {
        "RODA identifier" => project2.roda_identifier,
        "Partner organisation identifier" => project2.delivery_partner_identifier,
        "Partner organisation" => partner_organisation2.name,
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
        "FQ2 2021-2022" => "100.00"
      }
    ])
  end

  scenario "downloading budgets for a delivery partner" do
    partner_organisation = create(:delivery_partner_organisation)

    report = create(:report)

    project = create(:project_activity, :newton_funded, extending_organisation: partner_organisation)

    create(:budget, financial_year: 2018, value: 100, parent_activity: project, report: report)
    create(:budget, financial_year: 2019, value: 80, parent_activity: project, report: report)
    create(:budget, financial_year: 2020, value: 75, parent_activity: project, report: report)
    create(:budget, financial_year: 2021, value: 20, parent_activity: project, report: report)

    visit exports_path
    click_link partner_organisation.name
    click_link "Newton Fund budgets"

    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document.size).to eq(1)

    expect(document).to match_array([
      {
        "RODA identifier" => project.roda_identifier,
        "Partner organisation identifier" => project.delivery_partner_identifier,
        "Partner organisation" => partner_organisation.name,
        "Level" => "Project (level C)",
        "Title" => project.title,
        "2018-2019" => "100.00",
        "2019-2020" => "80.00",
        "2020-2021" => "75.00",
        "2021-2022" => "20.00"
      }
    ])
  end

  scenario "downloading budgets for all delivery partners" do
    partner_organisation1, partner_organisation2 = create_list(:delivery_partner_organisation, 2)

    report = create(:report)

    programme = create(:programme_activity)
    project1 = create(:project_activity, :newton_funded, extending_organisation: partner_organisation1, parent: programme)
    project2 = create(:project_activity, :newton_funded, extending_organisation: partner_organisation2, parent: programme)

    create(:budget, financial_year: 2018, value: 100, parent_activity: project1, report: report)
    create(:budget, financial_year: 2019, value: 80, parent_activity: project1, report: report)
    create(:budget, financial_year: 2021, value: 20, parent_activity: project1, report: report)

    create(:budget, financial_year: 2018, value: 100, parent_activity: project2, report: report)
    create(:budget, financial_year: 2019, value: 80, parent_activity: project2, report: report)
    create(:budget, financial_year: 2020, value: 75, parent_activity: project2, report: report)
    create(:budget, financial_year: 2021, value: 20, parent_activity: project2, report: report)
    create(:budget, financial_year: 2021, value: 60, parent_activity: project2, report: report)

    visit exports_path
    click_link "Download Budgets for Newton Fund"

    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document.size).to eq(3)

    expect(document).to match_array([
      {
        "RODA identifier" => project1.roda_identifier,
        "Partner organisation identifier" => project1.delivery_partner_identifier,
        "Partner organisation" => partner_organisation1.name,
        "Level" => "Project (level C)",
        "Title" => project1.title,
        "2018-2019" => "100.00",
        "2019-2020" => "80.00",
        "2020-2021" => "0.00",
        "2021-2022" => "20.00"
      },
      {
        "RODA identifier" => project2.roda_identifier,
        "Partner organisation identifier" => project2.delivery_partner_identifier,
        "Partner organisation" => partner_organisation2.name,
        "Level" => "Project (level C)",
        "Title" => project2.title,
        "2018-2019" => "100.00",
        "2019-2020" => "80.00",
        "2020-2021" => "75.00",
        "2021-2022" => "20.00"
      },
      {
        "RODA identifier" => project2.roda_identifier,
        "Partner organisation identifier" => project2.delivery_partner_identifier,
        "Partner organisation" => partner_organisation2.name,
        "Level" => "Project (level C)",
        "Title" => project2.title,
        "2018-2019" => "0.00",
        "2019-2020" => "0.00",
        "2020-2021" => "0.00",
        "2021-2022" => "60.00"
      }
    ])
  end
end
