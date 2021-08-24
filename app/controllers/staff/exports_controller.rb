class Staff::ExportsController < Staff::BaseController
  include Secured

  def index
    authorize :export
    add_breadcrumb t("breadcrumbs.export.index"), :exports_path

    @organisations = policy_scope(Organisation).delivery_partner
  end
end
