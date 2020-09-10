class TransactionPolicy < ApplicationPolicy
  def create?
    Pundit.policy!(user, record.parent_activity).create? && associated_report.present?
  end

  def update?
    return false if associated_report&.approved?
    Pundit.policy!(user, record.parent_activity).update? && associated_report.present?
  end

  def destroy?
    Pundit.policy!(user, record.parent_activity).destroy?
  end

  private

  def associated_report
    parent_activity = record.parent_activity
    organisation = parent_activity.organisation
    fund = parent_activity.associated_fund
    Report.find_by(organisation: organisation, fund: fund, state: [:active, :awaiting_changes])
  end
end
