class AdjustmentPolicy < ApplicationPolicy
  def new?
    return false if record.parent_activity.level.nil?
    return true if partner_organisation_user? && editable_report_exists?

    false
  end

  def create?
    return false if record.parent_activity.level.nil?
    return true if partner_organisation_user? && editable_report_exists?

    false
  end

  def show?
    return true if beis_user?
    record.parent_activity.organisation == user.organisation
  end

  private

  def editable_report_exists?
    editable_report.present?
  end

  def editable_report
    Report.editable_for_activity(record.parent_activity)
  end

  def activity_is_a_programme?
    record.parent_activity.programme?
  end
end
