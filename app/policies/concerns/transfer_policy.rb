module TransferPolicy
  extend ActiveSupport::Concern

  def show?
    return true if beis_user?

    if target_activity.project? || target_activity.third_party_project?
      user.organisation == target_activity.organisation
    end
  end

  def create?
    return beis_user? if target_activity.fund? || target_activity.programme?

    if partner_organisation_user?
      user.organisation == target_activity.organisation && editable_report_for_organisation_and_fund.present?
    end
  end

  def update?
    return beis_user? if target_activity.fund? || target_activity.programme?

    if partner_organisation_user?
      user.organisation == target_activity.organisation && record.report&.editable?
    end
  end

  def destroy?
    return beis_user? if target_activity.programme?

    if partner_organisation_user?
      user.organisation == target_activity.organisation && record.report&.editable?
    end
  end

  private def editable_report_for_organisation_and_fund
    Report.editable_for_activity(target_activity)
  end
end
