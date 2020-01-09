# frozen_string_literal: true

module ApplicationHelper
  def l(object, options = {})
    super(object, options) if object
  end

  def navigation_item_class(path)
    classes = ["govuk-header__navigation-item"]
    classes << "govuk-header__navigation-item--active" if current_page?(path)
    return classes.join(" ")
  end
end
