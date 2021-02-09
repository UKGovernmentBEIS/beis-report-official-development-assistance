class PagesController < ApplicationController
  include HighVoltage::StaticPage
  include Pundit
end
