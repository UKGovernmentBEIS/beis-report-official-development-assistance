class ActivityPolicy < ApplicationPolicy
  def show?
    record.fund? && beis_user? ||
      record.programme?
  end

  def create?
    record.fund? && beis_user? ||
      record.programme? && beis_user?
  end

  def update?
    record.fund? && beis_user? ||
      record.programme? && beis_user?
  end

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        scope.none
      end
    end
  end
end
