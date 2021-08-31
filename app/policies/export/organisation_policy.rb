module Export
  class OrganisationPolicy < ApplicationPolicy
    def index?
      user.service_owner?
    end

    def show?
      return true if user.service_owner?
    end
  end
end
