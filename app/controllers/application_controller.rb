class ApplicationController < ActionController::Base
  include Auth
  include Ip

  before_action -> {
    @organisation_list = current_user.organisations

    if session[:current_organisation]
      Current.organisation = session[:current_organisation]
    end
  }, if: :user_signed_in?

  private

  def add_breadcrumb(name, path, options = {})
    super name, path, options.merge(title: name)
  end
end
