class ActivityPolicy < ApplicationPolicy
  def show?
    return true if beis_user?
    return true if record.organisation == user.organisation
    return true if record.programme? && record.extending_organisation_id == user.organisation.id
    false
  end

  def create?
    if beis_user?
      return true if record.fund? || record.programme?
    end
    return false if editable_report_for_organisation.nil?
    record.organisation == user.organisation
  end

  def edit?
    update?
  end

  def update?
    return true if beis_user? && record.organisation == user.organisation

    if delivery_partner_user?
      return false if record.organisation != user.organisation
      return false if record.fund? || record.programme?
      return false if editable_report_for_organisation_and_fund.nil?
      return true
    end
    false
  end

  def redact_from_iati?
    if beis_user?
      return true if record.project? || record.third_party_project?
    end
    false
  end

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end

  private def editable_report_for_organisation
    Report.editable.find_by(organisation: record.organisation)
  end

  private def editable_report_for_organisation_and_fund
    fund = record.parent.associated_fund
    Report.editable.find_by(organisation: record.organisation, fund: fund)
  end
end
