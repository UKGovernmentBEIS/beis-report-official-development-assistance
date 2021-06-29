class Staff::HomeController < Staff::BaseController
  def show
    authorize :home, :show?
    redirect_if_delivery_partner
  end

  private def redirect_if_delivery_partner
    redirect_to organisation_path(current_user.organisation) unless current_user.service_owner?
  end
end
