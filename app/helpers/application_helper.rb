# frozen_string_literal: true

module ApplicationHelper
  def l(object, options = {})
    super(object, options) if object
  end

  def navigation_item_class(path)
    classes = ["govuk-header__navigation-item"]
    classes << "govuk-header__navigation-item--active" if current_page?(path)
    classes.join(" ")
  end

  def a11y_action_link(text, href, context = "")
    if context.blank?
      link_to(text, href, class: "govuk-link")
    else
      span = content_tag :span, context, class: "govuk-visually-hidden"
      link_to("#{text} #{raw(span)}".html_safe, href, class: "govuk-link")
    end
  end

  def link_to_new_tab(text, href, css_class: "govuk-link")
    link_to("#{text} (opens in new tab)", href, class: css_class, target: "_blank", rel: "noreferrer noopener")
  end
end
