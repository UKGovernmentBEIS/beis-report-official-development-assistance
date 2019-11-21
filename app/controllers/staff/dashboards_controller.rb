class Staff::DashboardsController < Staff::BaseController
  def show
    authorize :dashboard, :show?
  end
end
