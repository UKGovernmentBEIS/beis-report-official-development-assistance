class ActualPolicy < ApplicationPolicy
  def show?
    return true if beis_user?
    record.parent_activity.organisation == user.organisation
  end

  def create?
    return false if record.parent_activity.level.nil?
    return true if beis_user? && parent_activity_is_a_programme?
    return true if partner_organisation_user? && editable_report_for_organisation_and_fund.present?

    false
  end

  def update?
    can_update_or_delete?
  end

  def destroy?
    can_update_or_delete?
  end

  def create_comment?
    return false if beis_user?

    partner_organisation_user? &&
      editable_report_for_organisation_and_fund.present? &&
      editable_report_for_organisation_and_fund == record.report
  end

  private def can_update_or_delete?
    return false if record.parent_activity.level.nil?
    return true if beis_user? && parent_activity_is_a_programme?

    if partner_organisation_user? && editable_report_for_organisation_and_fund.present?
      return true if editable_report_for_organisation_and_fund == record.report
    end

    false
  end

  private def editable_report_for_organisation_and_fund
    Report.editable_for_activity(record.parent_activity)
  end

  private def parent_activity_is_a_programme?
    record.parent_activity.programme?
  end
end
