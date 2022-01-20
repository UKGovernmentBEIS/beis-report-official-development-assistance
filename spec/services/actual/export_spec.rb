RSpec.describe Actual::Export do
  let(:delivery_partner) { create(:delivery_partner_organisation) }
  let(:activities) { Activity.where(organisation: delivery_partner) }
  let(:export) { Actual::Export.new(activities) }

  let :quarter_headers do
    export.headers.drop(2)
  end

  let :actual_data do
    export.rows.map { |row| row.take(1) + row.drop(2) }
  end

  it "exports an empty data set" do
    project = create(:project_activity, organisation: delivery_partner)

    expect(quarter_headers).to eq []

    expect(actual_data).to eq([
      [project.roda_identifier]
    ])
  end

  it "exports one quarter of spend for a single project" do
    project = create(:project_activity, organisation: delivery_partner)

    create(:actual, parent_activity: project, financial_year: 2014, financial_quarter: 1, value: 10)
    create(:actual, parent_activity: project, financial_year: 2014, financial_quarter: 1, value: 20)

    expect(quarter_headers).to eq ["FQ1 2014-2015"]

    expect(actual_data).to eq([
      [project.roda_identifier, "30.00"]
    ])
  end

  it "exports two quarters of spend for a single project with zeros for intervening quarters" do
    project = create(:project_activity, organisation: delivery_partner)

    create(:actual, parent_activity: project, financial_year: 2014, financial_quarter: 1, value: 10)
    create(:actual, parent_activity: project, financial_year: 2014, financial_quarter: 4, value: 20)

    expect(quarter_headers).to eq ["FQ1 2014-2015", "FQ2 2014-2015", "FQ3 2014-2015", "FQ4 2014-2015"]

    expect(actual_data).to eq([
      [project.roda_identifier, "10.00", "0.00", "0.00", "20.00"]
    ])
  end

  it "exports actual spend for two activities across different quarters" do
    project = create(:project_activity, organisation: delivery_partner)
    third_party_project = create(:third_party_project_activity, organisation: delivery_partner)

    create(:actual, parent_activity: project, financial_year: 2014, financial_quarter: 1, value: 10)
    create(:actual, parent_activity: third_party_project, financial_year: 2015, financial_quarter: 2, value: 20)

    expect(quarter_headers).to eq ["FQ1 2014-2015", "FQ2 2014-2015", "FQ3 2014-2015", "FQ4 2014-2015", "FQ1 2015-2016", "FQ2 2015-2016"]

    expect(actual_data).to match_array([
      [project.roda_identifier, "10.00", "0.00", "0.00", "0.00", "0.00", "0.00"],
      [third_party_project.roda_identifier, "0.00", "0.00", "0.00", "0.00", "0.00", "20.00"]
    ])
  end

  it "includes activities that do not have any actuals recorded" do
    project = create(:project_activity, organisation: delivery_partner)
    third_party_project = create(:third_party_project_activity, organisation: delivery_partner)

    create(:actual, parent_activity: project, financial_year: 2014, financial_quarter: 1, value: 10)

    expect(quarter_headers).to eq ["FQ1 2014-2015"]

    expect(actual_data).to match_array([
      [project.roda_identifier, "10.00"],
      [third_party_project.roda_identifier, "0.00"]
    ])
  end
end
