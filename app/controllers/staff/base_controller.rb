class Staff::BaseController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :pundit_not_authorized

  include Secured
  include Authorisation
  include Pundit

  # Ensure that Pundit 'authorize' and scopes are used
  after_action :verify_authorized, :verify_policy_scoped

  def pundit_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to dashboard_path
  end
end
