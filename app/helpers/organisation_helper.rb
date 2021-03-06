module OrganisationHelper
  def organisation_page_back_link(current_user, params)
    if current_user_on_home_page?(current_user, params)
      nil
    else
      link_to t("default.link.back"), organisations_path, class: "govuk-back-link"
    end
  end

  private

  def current_user_on_home_page?(current_user, params)
    params[:controller].eql?("staff/organisations") &&
      params[:action].eql?("show") &&
      params[:id].eql?(current_user.organisation.id)
  end
end
