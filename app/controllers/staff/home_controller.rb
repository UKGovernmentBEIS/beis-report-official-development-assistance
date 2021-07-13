class Staff::HomeController < Staff::BaseController
  def show
    authorize :home, :show?

    if current_user.service_owner?
      @delivery_partner_organisations = Organisation.delivery_partners
      authorize @delivery_partner_organisations
      render :service_owner
    else
      @grouped_activities = Activity::GroupedActivitiesFetcher.new(
        user: current_user,
        organisation: current_user.organisation,
        scope: :current
      ).call
      render :delivery_partner
    end
  end
end
