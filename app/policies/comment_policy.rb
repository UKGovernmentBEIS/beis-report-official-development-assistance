class CommentPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    true
  end

  def show?
    return true if beis_user?
    user.organisation == record.report.organisation
  end

  def create?
    return false if beis_user?
    !editable_report_for_organisation.nil?
  end

  def edit?
    update?
  end

  def update?
    return false if beis_user?
    editable_report_for_organisation_and_fund && record.owner.organisation == user.organisation
  end

  def destroy?
    false
  end

  private def editable_report_for_organisation
    Report.editable.find_by(organisation: user.organisation)
  end

  private def editable_report_for_organisation_and_fund
    fund = record.activity.associated_fund
    Report.editable.find_by(organisation: record.owner.organisation, fund: fund)
  end
end
