require "rails_helper"

RSpec.describe Activity::ProjectsForReportFinder do
  it "only returns projects and third party projects that are for the report's organisation and fund" do
    organisation = create(:delivery_partner_organisation)
    newton_fund = create(:fund_activity, :newton)
    report = create(:report, organisation: organisation, fund: newton_fund)

    programme = create(:programme_activity, :newton_funded, parent: newton_fund)
    project = create(:project_activity, :newton_funded, organisation: organisation, parent: programme)
    third_party_project = create(:third_party_project_activity, :newton_funded, organisation: organisation, parent: project)

    gcrf_fund = create(:fund_activity, :gcrf)
    another_programme = create(:programme_activity, :gcrf_funded, parent: gcrf_fund)
    another_project = create(:project_activity, :gcrf_funded, organisation: organisation, parent: another_programme)
    another_third_party_project = create(:third_party_project_activity, :gcrf_funded, organisation: organisation, parent: another_project)

    result = Activity::ProjectsForReportFinder.new(report: report).call

    expect(result).to include third_party_project
    expect(result).to include project

    expect(result).not_to include newton_fund
    expect(result).not_to include programme
    expect(result).not_to include gcrf_fund
    expect(result).not_to include another_programme
    expect(result).not_to include another_project
    expect(result).not_to include another_third_party_project
  end
end
