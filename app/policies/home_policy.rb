class HomePolicy < ApplicationPolicy
  def show?
    return true if beis_user? || partner_organisation_user?
    false
  end
end
