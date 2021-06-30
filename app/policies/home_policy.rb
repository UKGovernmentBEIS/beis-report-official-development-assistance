class HomePolicy < ApplicationPolicy
  def show?
    return true if beis_user? || delivery_partner_user?
    false
  end
end
