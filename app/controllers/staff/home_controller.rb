class Staff::HomeController < Staff::BaseController
  def show
    authorize :home, :show?

    if current_user.service_owner?
      @delivery_partner_organisations = Organisation.delivery_partners
      authorize @delivery_partner_organisations
      render :service_owner
    else
      render :delivery_partner
    end
  end
end
