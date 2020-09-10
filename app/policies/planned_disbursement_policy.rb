class PlannedDisbursementPolicy < ApplicationPolicy
  def create?
    return false if record.parent_activity.fund? || record.parent_activity.programme?
    Pundit.policy!(user, record.parent_activity).create? && associated_report.present?
  end

  def update?
    return false if record.parent_activity.fund? || record.parent_activity.programme?
    return false if associated_report&.approved?
    Pundit.policy!(user, record.parent_activity).update? && associated_report.present?
  end

  def destroy?
    false
  end

  private

  def associated_report
    parent_activity = record.parent_activity
    organisation = parent_activity.organisation
    fund = parent_activity.associated_fund
    Report.find_by(organisation: organisation, fund: fund, state: [:active, :awaiting_changes])
  end
end
