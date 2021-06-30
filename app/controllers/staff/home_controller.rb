class Staff::HomeController < Staff::BaseController
  def show
    authorize :home, :show?

    if current_user.service_owner?
      @delivery_partner_organisations = Organisation.delivery_partners
      authorize @delivery_partner_organisations
    else
      redirect_to organisation_path(current_user.organisation)
    end
  end
end
