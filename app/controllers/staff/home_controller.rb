class Staff::HomeController < Staff::BaseController
  def show
    authorize :home, :show?

    if current_user.service_owner?
      @delivery_partner_organisations = Organisation.delivery_partners
      authorize @delivery_partner_organisations
      render :service_owner
    else
      @grouped_programmes = fetch_grouped_programmes_for(current_user.organisation, :current)
      render :delivery_partner
    end
  end

  private def fetch_grouped_programmes_for(organisation, scope)
    activities = policy_scope(
      Activity.includes(
        :organisation,
        parent: [:parent, :organisation],
        child_activities: [:child_activities, :organisation, :parent]
      ).programme
       .send(scope)
    )
    activities = activities.where(extending_organisation: organisation)
    activities.order(:roda_identifier_compound)
      .group_by(&:parent)
  end
end
