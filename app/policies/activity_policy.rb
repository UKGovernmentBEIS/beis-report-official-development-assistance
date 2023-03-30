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

    if partner_organisation_user?
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

    if partner_organisation_user?
      return false if record.organisation != user.organisation
      return false if record.fund? || record.programme?
      return false unless editable_report?
      return true
    end
    false
  end

  def show_xml?
    return false unless record.is_project?
    beis_user?
  end

  def redact_from_iati?
    if beis_user?
      return true unless record.fund?
    end
    false
  end

  def update_linked_activity?
    return unless ROLLOUT.active?(:activity_linking) && record.is_ispf_funded?

    if record.programme?
      return beis_user? && record.linked_child_activities.empty?
    end

    if record.is_project?
      return false unless editable_report? && record.linked_child_activities.empty?
      beis_user? || partner_organisation_user? && record.organisation == user.organisation
    end
  end

  def set_commitment?
    return false if record.fund?
    return true if beis_user?

    record.commitment.nil? && editable_report? && record.organisation == user.organisation
  end

  def destroy?
    return false if record.fund?
    return true if record.title.blank? && beis_user?
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
