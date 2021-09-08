class ExportPolicy < ApplicationPolicy
  def index?
    user.service_owner?
  end
end
