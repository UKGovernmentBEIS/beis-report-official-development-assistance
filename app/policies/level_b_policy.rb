class LevelBPolicy < ApplicationPolicy
  def activity_upload?
    true if beis_user?
  end

  def budget_upload?
    true if beis_user?
  end

  def create_activity_comment?
    update_activity_comment?
  end

  def update_activity_comment?
    true if beis_user?
  end
end
