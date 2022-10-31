class LevelBPolicy < ApplicationPolicy
  def activity_upload?
    return true if beis_user?
  end

  def budget_upload?
    return true if beis_user?
  end

  def create_activity_comment?
    update_activity_comment?
  end

  def update_activity_comment?
    return true if beis_user?
  end
end
