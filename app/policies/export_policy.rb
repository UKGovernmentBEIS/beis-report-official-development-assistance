class ExportPolicy < ApplicationPolicy
  def index?
    user.service_owner?
  end

  def show?
    user.service_owner?
  end
end
