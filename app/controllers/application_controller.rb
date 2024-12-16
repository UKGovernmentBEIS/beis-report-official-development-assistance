class ApplicationController < ActionController::Base
  include Auth
  include Ip

  before_action :set_organisation_list_and_current_organisation

  private

  def set_organisation_list_and_current_organisation
    return unless user_signed_in?

    @organisation_list = current_user.all_organisations
    if session[:current_user_organisation]
      Current.user_organisation = session[:current_user_organisation]
    end
  end

  def add_breadcrumb(name, path, options = {})
    super(name, path, options.merge(title: name))
  end
end
