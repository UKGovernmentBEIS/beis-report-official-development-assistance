class Staff::ExportsController < Staff::BaseController
  include Secured

  def index
    authorize :export
    @organisations = policy_scope(Organisation).delivery_partner
  end
end
