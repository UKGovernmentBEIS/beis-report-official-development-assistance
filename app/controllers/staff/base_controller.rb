class Staff::BaseController < ApplicationController
  include Secured
  include Auth
  include Pundit

  # Ensure that Pundit 'authorize' and scopes are used
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  add_breadcrumb "Home", :root_path

  before_action :clear_breadcrumb_context

  def clear_breadcrumb_context
    BreadcrumbContext.new(session).reset!
  end
end
