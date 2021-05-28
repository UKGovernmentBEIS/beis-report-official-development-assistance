class Staff::ExportsController < Staff::BaseController
  include Secured

  def index
    @organisations = policy_scope(Organisation).delivery_partner
  end
end
