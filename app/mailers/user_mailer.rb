class UserMailer < ApplicationMailer
  def welcome(user)
    token = user.send(:set_reset_password_token)

    template_mail(
      NOTIFY_WELCOME_EMAIL_TEMPLATE,
      to: user.email,
      personalisation: {
        name: user.name,
        link: edit_user_password_url(reset_password_token: token),
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

  def first_time_devise_reset_password_instructions(user, token, opts = {})
    @token = token

    view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
      to: user.email,
      subject: t("devise.mailer.first_time_devise_reset_password_instructions.subject"))
  end
end
