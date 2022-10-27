RSpec.feature "BEIS users can download exports" do
  let(:beis_user) { create(:beis_user) }

  before do
    authenticate! user: beis_user
  end
  after { logout }

  scenario "downloading the actuals for a partner organisation" do
    partner_organisation = create(:partner_organisation)
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

  scenario "downloading the external income for a partner organisation" do
    partner_organisation = create(:partner_organisation)
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
        "Partner organisation identifier" => project.partner_organisation_identifier,
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
        "Partner organisation identifier" => project.partner_organisation_identifier,
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

  scenario "downloading the external income for all partner organisations" do
    partner_organisation1, partner_organisation2 = create_list(:partner_organisation, 2)
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
        "Partner organisation identifier" => project1.partner_organisation_identifier,
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
        "Partner organisation identifier" => project2.partner_organisation_identifier,
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
        "Partner organisation identifier" => project2.partner_organisation_identifier,
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

  scenario "downloading budgets for a partner organisation" do
    partner_organisation = create(:partner_organisation)

    report = create(:report)

    programme = create(:programme_activity, extending_organisation: partner_organisation)
    project = create(:project_activity, :newton_funded, extending_organisation: partner_organisation)

    create(:budget, financial_year: 2021, value: 1000, parent_activity: programme, report: nil)

    create(:budget, financial_year: 2018, value: 100, parent_activity: project, report: report)
    create(:budget, financial_year: 2019, value: 80, parent_activity: project, report: report)
    create(:budget, financial_year: 2020, value: 75, parent_activity: project, report: report)
    create(:budget, financial_year: 2021, value: 20, parent_activity: project, report: report)

    programme_comment = create(:comment, commentable: programme, owner: beis_user, body: "I am a programme comment")

    visit exports_path
    click_link partner_organisation.name
    click_link "Newton Fund budgets"

    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document.size).to eq(2)

    expect(document).to match_array([
      {
        "RODA identifier" => programme.roda_identifier,
        "Partner organisation identifier" => programme.partner_organisation_identifier,
        "Partner organisation" => programme.extending_organisation.name,
        "Level" => "Programme (level B)",
        "Title" => programme.title,
        "Level B activity comments" => programme_comment.body,
        "2018-2019" => "0.00",
        "2019-2020" => "0.00",
        "2020-2021" => "0.00",
        "2021-2022" => "1000.00"
      },
      {
        "RODA identifier" => project.roda_identifier,
        "Partner organisation identifier" => project.partner_organisation_identifier,
        "Partner organisation" => partner_organisation.name,
        "Level" => "Project (level C)",
        "Title" => project.title,
        "Level B activity comments" => "",
        "2018-2019" => "100.00",
        "2019-2020" => "80.00",
        "2020-2021" => "75.00",
        "2021-2022" => "20.00"
      }
    ])
  end

  scenario "downloading budgets for all partner organisations" do
    partner_organisation1, partner_organisation2 = create_list(:partner_organisation, 2)

    report = create(:report)

    programme = create(:programme_activity)
    project1 = create(:project_activity, :newton_funded, extending_organisation: partner_organisation1, parent: programme)
    project2 = create(:project_activity, :newton_funded, extending_organisation: partner_organisation2, parent: programme)

    create(:budget, financial_year: 2021, value: 1000, parent_activity: programme, report: nil)

    create(:budget, financial_year: 2018, value: 100, parent_activity: project1, report: report)
    create(:budget, financial_year: 2019, value: 80, parent_activity: project1, report: report)
    create(:budget, financial_year: 2021, value: 20, parent_activity: project1, report: report)

    create(:budget, financial_year: 2018, value: 100, parent_activity: project2, report: report)
    create(:budget, financial_year: 2019, value: 80, parent_activity: project2, report: report)
    create(:budget, financial_year: 2020, value: 75, parent_activity: project2, report: report)
    create(:budget, financial_year: 2021, value: 20, parent_activity: project2, report: report)
    create(:budget, financial_year: 2021, value: 60, parent_activity: project2, report: report)

    programme_comment_1 = create(:comment, commentable: programme, owner: beis_user, body: "I like big budgets and I cannot lie")
    programme_comment_2 = create(:comment, commentable: programme, owner: beis_user, body: "The chief budgerigar asked if we could budge over this budget")

    visit exports_path
    click_link "Download Budgets for Newton Fund"

    document = CSV.parse(page.body.delete_prefix("\uFEFF"), headers: true).map(&:to_h)

    expect(document.size).to eq(4)

    expect(document).to match_array([
      {
        "RODA identifier" => programme.roda_identifier,
        "Partner organisation identifier" => programme.partner_organisation_identifier,
        "Partner organisation" => programme.extending_organisation.name,
        "Level" => "Programme (level B)",
        "Title" => programme.title,
        "Level B activity comments" => [programme_comment_1, programme_comment_2].map(&:body).join("|"),
        "2018-2019" => "0.00",
        "2019-2020" => "0.00",
        "2020-2021" => "0.00",
        "2021-2022" => "1000.00"
      },
      {
        "RODA identifier" => project1.roda_identifier,
        "Partner organisation identifier" => project1.partner_organisation_identifier,
        "Partner organisation" => partner_organisation1.name,
        "Level" => "Project (level C)",
        "Title" => project1.title,
        "Level B activity comments" => "",
        "2018-2019" => "100.00",
        "2019-2020" => "80.00",
        "2020-2021" => "0.00",
        "2021-2022" => "20.00"
      },
      {
        "RODA identifier" => project2.roda_identifier,
        "Partner organisation identifier" => project2.partner_organisation_identifier,
        "Partner organisation" => partner_organisation2.name,
        "Level" => "Project (level C)",
        "Title" => project2.title,
        "Level B activity comments" => "",
        "2018-2019" => "100.00",
        "2019-2020" => "80.00",
        "2020-2021" => "75.00",
        "2021-2022" => "20.00"
      },
      {
        "RODA identifier" => project2.roda_identifier,
        "Partner organisation identifier" => project2.partner_organisation_identifier,
        "Partner organisation" => partner_organisation2.name,
        "Level" => "Project (level C)",
        "Title" => project2.title,
        "Level B activity comments" => "",
        "2018-2019" => "0.00",
        "2019-2020" => "0.00",
        "2020-2021" => "0.00",
        "2021-2022" => "60.00"
      }
    ])
  end
end
