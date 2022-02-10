# require "./lib/auth0_api"

class UserMailer < ApplicationMailer
  def welcome(user)
    template_mail(
      NOTIFY_WELCOME_EMAIL_TEMPLATE,
      to: user.email,
      personalisation: {
        name: user.name,
        link: "ftp://TODO", # TODO: take this from Devise: password_change_link(user: user),
        service_url: ENV["DOMAIN"]
      }
    )
  end

  def reset_password_instructions(user, token, opts = {})
    @token = token

    view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
      to: user.email,
      subject: t("devise.mailer.reset_password_instructions.subject"))
  end

  def password_change_link(user:)
    Auth0Api.new.client.post_password_change(
      user_id: user.identifier,
      result_url: organisation_url(user.organisation)
    )["ticket"]
  end
end
