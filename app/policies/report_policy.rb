class ReportPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    true
  end

  def show?
    return true if beis_user?
    return true if record.organisation == user.organisation && record.state != "inactive"
    false
  end

  def create?
    false
  end

  def edit?
    update?
  end

  def update?
    beis_user?
  end

  def destroy?
    false
  end

  def change_state?
    case record.state
    when "inactive"
      beis_user?
    when "active"
      delivery_partner_user?
    when "submitted"
      beis_user?
    when "in_review"
      beis_user?
    when "awaiting_changes"
      delivery_partner_user?
    when "approved"
      false
    end
  end

  def upload?
    record.editable? && record.organisation == user.organisation
  end

  def download?
    show?
  end

  def activate?
    return change_state? if record.state == "inactive"
  end

  def submit?
    return change_state? if record.editable?
  end

  def review?
    return change_state? if record.state == "submitted"
  end

  def request_changes?
    return change_state? if record.state == "in_review"
  end

  def approve?
    return change_state? if record.state == "in_review"
  end

  class Scope < Scope
    def resolve
      if user.organisation.service_owner?
        scope.all
      else
        scope.where(organisation: user.organisation)
      end
    end
  end
end
