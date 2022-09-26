class LevelBPolicy < ApplicationPolicy
  def activity_upload?
    return true if beis_user?
  end

  def budget_upload?
    return true if beis_user?
  end
end
