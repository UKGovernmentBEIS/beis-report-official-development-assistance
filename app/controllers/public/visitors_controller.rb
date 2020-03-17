class Public::VisitorsController < Public::BaseController
  def index
    redirect_to organisation_path(current_user.organisation) if current_user&.active?
  end
end
