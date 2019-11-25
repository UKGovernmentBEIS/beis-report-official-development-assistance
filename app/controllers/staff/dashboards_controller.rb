class Staff::DashboardsController < Staff::BaseController
  def show
    skip_policy_scope # We're not performing any queries here

    authorize :dashboard, :show?
  end
end
