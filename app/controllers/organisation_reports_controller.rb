class OrganisationReportsController < BaseController
  skip_after_action :verify_policy_scoped

  def index
    authorize organisation, :show?

    @reports = Report::OrganisationReportsFetcher.new(organisation: organisation)

    add_breadcrumb "Reports", :organisation_reports_path

    render "organisations/reports/index"
  end

  private def organisation
    @organisation ||= Organisation.find(params[:organisation_id])
  end
end
