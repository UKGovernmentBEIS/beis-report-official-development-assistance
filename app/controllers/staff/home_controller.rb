class Staff::HomeController < Staff::BaseController
  def show
    authorize :home, :show?

    if current_user.service_owner?
      @partner_organisations = Organisation.partner_organisations
      authorize @partner_organisations
      render :service_owner
    else
      @grouped_activities = Activity::GroupedActivitiesFetcher.new(
        user: current_user,
        organisation: current_user.organisation,
        scope: :current
      ).call
      @reports = Report::OrganisationReportsFetcher.new(organisation: current_user.organisation).current
      render :partner_organisation
    end
  end
end
