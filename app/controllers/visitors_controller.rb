# frozen_string_literal: true

class VisitorsController < ApplicationController
  skip_before_action :logged_in_using_omniauth?
end
