class ApplicationController < ActionController::Base
  include Auth
  include Ip

  before_action -> {
    @organisation_list = current_user.organisations
    Current.organisation = session[:current_organisation] || current_user.primary_organisation.id
  }, if: :user_signed_in?

  private

  def add_breadcrumb(name, path, options = {})
    super name, path, options.merge(title: name)
  end
end
