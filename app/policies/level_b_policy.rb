class LevelBPolicy < ApplicationPolicy
  def budget_upload?
    return true if beis_user?
  end
end
