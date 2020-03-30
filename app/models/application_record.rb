# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include PublicActivity::Common

  self.abstract_class = true
end
