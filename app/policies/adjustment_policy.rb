class AdjustmentPolicy < ApplicationPolicy
  def new?
    return false if record.parent_activity.level.nil?
    return true if delivery_partner_user? && active_report_exists?

    false
  end

  def create?
    return false if record.parent_activity.level.nil?
    return true if delivery_partner_user? && active_report_exists?

    false
  end

  def show?
    return true if beis_user?
    record.parent_activity.organisation == user.organisation
  end

  private

  def active_report_exists?
    active_report.any?
  end

  def active_report
    Report.for_activity(record.parent_activity).where(state: "active")
  end

  def activity_is_a_programme?
    record.parent_activity.programme?
  end
end
