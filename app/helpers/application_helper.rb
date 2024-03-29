# frozen_string_literal: true

module ApplicationHelper
  SUPPORT_EMAIL_ADDRESS = "support@beisodahelp.zendesk.com"

  def l(object, options = {})
    super(object, **options) if object
  end

  def navigation_item_class(path)
    classes = ["govuk-header__navigation-item"]
    classes << "govuk-header__navigation-item--active" if current_page?(path)
    classes.join(" ")
  end

  def a11y_action_link(text, href, context = "", classes = [])
    css_classes = classes.append("govuk-link")
    if context.blank?
      link_to(text, href, class: css_classes)
    else
      span = content_tag :span, " #{context}", class: "govuk-visually-hidden"
      link_to(safe_join([text, span]), href, class: css_classes)
    end
  end

  def link_to_new_tab(text, href, css_class: "govuk-link")
    link_to("#{text} (opens in new tab)", href, class: css_class, target: "_blank", rel: "noreferrer noopener")
  end

  def support_email_link
    mail_to(SUPPORT_EMAIL_ADDRESS, nil, class: "govuk-link")
  end

  def breadcrumb_tags
    content_tag :nav, class: "govuk-breadcrumbs", aria: {label: "Breadcrumbs"} do
      content_tag :ol, class: "govuk-breadcrumbs__list" do
        render_breadcrumbs tag: :li, separator: ""
      end
    end
  end

  def environment_name
    hostname = ENV.fetch("DOMAIN", "").sub("https://", "").split(".").first

    case hostname
    when "www"
      "production"
    when "dev", "sandbox", "staging", "training"
      hostname
    else
      Rails.env
    end
  end

  def display_env_name?
    environment_name.in? %w[dev development sandbox staging training]
  end

  def environment_mailer_prefix
    return "" unless display_env_name?

    "[#{environment_name.titleize}] "
  end
end
