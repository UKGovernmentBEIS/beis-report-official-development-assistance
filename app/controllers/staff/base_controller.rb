class Staff::BaseController < ApplicationController
  include Secured
  include Authorisation
end
