class PlannedDisbursementPolicy < ApplicationPolicy
  def show?
    return true if beis_user?
    record.parent_activity.organisation == user.organisation
  end

  def create?
    return false if record.parent_activity.level.nil?
    return true if beis_user? && record.parent_activity.programme?

    if delivery_partner_user?
      return true if editable_report_for_organisation_and_fund.present?
    end

    false
  end

  def update?
    return false if record.parent_activity.level.nil?
    return true if beis_user? && record.parent_activity.programme?

    if delivery_partner_user? && editable_report_for_organisation_and_fund.present?
      return true if editable_report_for_organisation_and_fund == record.report
    end

    false
  end

  def destroy?
    false
  end

  private def editable_report_for_organisation_and_fund
    activity = record.parent_activity
    Report.find_by(organisation: activity.organisation, fund: activity.associated_fund, state: Report::EDITABLE_STATES)
  end
end
