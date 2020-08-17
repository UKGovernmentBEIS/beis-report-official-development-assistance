class PlannedDisbursementPolicy < ApplicationPolicy
  def create?
    return false if record.parent_activity.fund? || record.parent_activity.programme?
    Pundit.policy!(user, record.parent_activity).create? && !!associated_report&.active?
  end

  def update?
    return false if record.parent_activity.fund? || record.parent_activity.programme?
    Pundit.policy!(user, record.parent_activity).update? && !!associated_report&.active?
  end

  def destroy?
    false
  end

  private

  def associated_report
    parent_activity = record.parent_activity
    organisation = parent_activity.organisation
    fund = parent_activity.associated_fund
    Report.find_by(organisation: organisation, fund: fund)
  end
end
