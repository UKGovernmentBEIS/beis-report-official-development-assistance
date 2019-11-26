# frozen_string_literal: true

module ApplicationHelper
  def l(object, options = {})
    super(object, options) if object
  end
end
