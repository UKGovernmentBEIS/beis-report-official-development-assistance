class ActivityPolicy < ApplicationPolicy
  def show?
    if record.level.blank?
      return record.organisation == user.organisation
    end

    record.fund? && beis_user? ||
      record.programme? ||
      record.project? ||
      record.third_party_project?
  end

  def create?
    record.organisation == user.organisation
  end

  def update?
    record.organisation == user.organisation
  end

  def redact_from_iati?
    beis_user? && record.project? || record.third_party_project?
  end

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
