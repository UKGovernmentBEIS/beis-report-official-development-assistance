module Export
  class OrganisationPolicy < ApplicationPolicy
    def index?
      user.service_owner?
    end

    def show?
      return true if user.service_owner?
      return true if user.partner_organisation? && user.organisation == record
    end

    def show_external_income?
      show?
    end

    def show_transactions?
      return true if user.service_owner?
    end

    def show_budgets?
      show?
    end

    def show_spending_breakdown?
      show?
    end

    def show_xml?
      return true if user.service_owner?
    end
  end
end
