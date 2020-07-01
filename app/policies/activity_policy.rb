class ActivityPolicy < ApplicationPolicy
  def show?
    record.fund? && beis_user? ||
      record.programme? ||
      record.project? ||
      record.third_party_project?
  end

  def create?
    record.fund? && beis_user? ||
      record.programme? && beis_user? ||
      (record.project? || record.third_party_project?) && delivery_partner_user?
  end

  def update?
    record.fund? && beis_user? ||
      record.programme? && beis_user? ||
      (record.project? || record.third_party_project?) && delivery_partner_user?
  end

  def redact_from_iati?
    beis_user? && record.project? || record.third_party_project?
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
