class Staff::OrganisationReportsController < Staff::BaseController
  skip_after_action :verify_policy_scoped

  def index
    authorize organisation, :show?

    @reports = Report::OrganisationReportsFetcher.new(organisation: organisation)

    render "staff/organisations/reports/index"
  end

  private def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end
end
