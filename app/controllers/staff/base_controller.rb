class Staff::BaseController < ApplicationController
  include Secured
  include Auth
  include Pundit

  # Ensure that Pundit 'authorize' and scopes are used
  after_action :verify_authorized, :verify_policy_scoped
end
