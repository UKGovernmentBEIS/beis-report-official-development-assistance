class Staff::BaseController < ApplicationController
  include Secured
  include Auth
  include Pundit

  # Ensure that Pundit 'authorize' and scopes are used
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  add_breadcrumb "Home", :root_path
end
