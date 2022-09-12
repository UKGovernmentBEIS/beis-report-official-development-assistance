class BudgetPolicy < ApplicationPolicy
  def show?
    return true if beis_user?
    record.parent_activity.organisation == user.organisation
  end

  def create?
    return false if record.parent_activity.level.nil?

    if beis_user?
      return true if record.parent_activity.fund? || record.parent_activity.programme?
    end

    if partner_organisation_user?
      return true if editable_report_for_organisation_and_fund.present?
    end

    false
  end

  def update?
    return false if record.parent_activity.level.nil?

    if beis_user?
      return true if record.parent_activity.fund? || record.parent_activity.programme?
    end

    if partner_organisation_user? && editable_report_for_organisation_and_fund.present?
      return true if editable_report_for_organisation_and_fund == record.report
    end

    false
  end

  def destroy?
    update?
  end

  private def editable_report_for_organisation_and_fund
    Report.editable_for_activity(record.parent_activity)
  end
end
