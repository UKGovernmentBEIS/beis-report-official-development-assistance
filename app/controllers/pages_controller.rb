class PagesController < ApplicationController
  include HighVoltage::StaticPage
  include Pundit::Authorization
end
