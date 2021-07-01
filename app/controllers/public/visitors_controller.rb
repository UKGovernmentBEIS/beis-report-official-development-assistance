class Public::VisitorsController < Public::BaseController
  def index
    redirect_to home_path if current_user&.active?
  end
end
