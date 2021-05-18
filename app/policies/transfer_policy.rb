class TransferPolicy < ApplicationPolicy
  def show?
    return true if beis_user?

    if record.source.project? || record.source.third_party_project?
      user.organisation == record.source.organisation
    end
  end

  def create?
    return beis_user? if record.source.fund? || record.source.programme?

    if delivery_partner_user?
      user.organisation == record.source.organisation && editable_report_for_organisation_and_fund.present?
    end
  end

  def update?
    return beis_user? if record.source.fund? || record.source.programme?

    if delivery_partner_user?
      user.organisation == record.source.organisation && record.report&.editable?
    end
  end

  def destroy?
    return beis_user? if record.source.programme?

    if delivery_partner_user?
      user.organisation == record.source.organisation && record.report&.editable?
    end
  end

  private def editable_report_for_organisation_and_fund
    Report.editable_for_activity(record.source)
  end
end
