class Staff::BaseController < ApplicationController
  include Secured
  include Authorisation
  include Pundit

  # Ensure that Pundit 'authorize' is called
  after_action :verify_authorized
end
