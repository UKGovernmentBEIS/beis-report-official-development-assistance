class ExportPolicy < ApplicationPolicy
  def index?
    user.service_owner?
  end

  def show_external_income?
    user.service_owner?
  end

  def show_budgets?
    user.service_owner?
  end

  def show_level_b?
    user.service_owner?
  end

  def show_spending_breakdown?
    user.service_owner?
  end

  def show_continuing_activities?
    user.service_owner?
  end
end
