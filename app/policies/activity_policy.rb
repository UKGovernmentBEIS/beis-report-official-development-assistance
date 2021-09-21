class ActivityPolicy < ApplicationPolicy
  def show?
    return true if beis_user?
    return true if record.organisation == user.organisation
    return true if record.programme? && record.extending_organisation_id == user.organisation.id
    false
  end

  def create?
    if beis_user?
      return true if record.fund? || record.programme?
    end
    return false unless editable_report?
    record.organisation == user.organisation
  end

  def create_child?
    return record.fund? if beis_user?

    return false if record.third_party_project?
    return false unless editable_report?

    record.extending_organisation == user.organisation
  end

  def create_transfer?
    return beis_user? if record.fund? || record.programme?

    if delivery_partner_user?
      record.organisation == user.organisation && Report.editable.for_activity(record).exists?
    end
  end

  def create_refund?
    Pundit.policy(
      user,
      Refund.new(parent_activity: record)
    ).create?
  end

  def create_adjustment?
    Pundit.policy(
      user,
      Adjustment.new(parent_activity: record)
    ).create?
  end

  def edit?
    update?
  end

  def update?
    return true if beis_user? && record.organisation == user.organisation

    if delivery_partner_user?
      return false if record.organisation != user.organisation
      return false if record.fund? || record.programme?
      return false unless editable_report?
      return true
    end
    false
  end

  def redact_from_iati?
    if beis_user?
      return true if record.project? || record.third_party_project?
    end
    false
  end

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end

  private

  def editable_report?
    fund = record.associated_fund

    Report.editable.where(
      fund_id: fund.id,
      organisation_id: [record.extending_organisation_id, record.organisation_id]
    ).exists?
  end
end
