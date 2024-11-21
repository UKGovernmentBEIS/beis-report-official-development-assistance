class DownloadLinkMailer < ApplicationMailer
  def send_link(recipient, file_name)
    @file_name = file_name
    @file_url = exports_url

    view_mail(
      ENV["NOTIFY_VIEW_TEMPLATE"],
      to: recipient.email,
      subject: t(
        "mailer.download_link.success.subject",
        application_name: t("app.title"),
        file_name: file_name,
        environment_name: environment_mailer_prefix
      )
    )
  end

  def send_failure_notification(recipient)
    view_mail(
      ENV["NOTIFY_VIEW_TEMPLATE"],
      to: recipient.email,
      subject: t(
        "mailer.download_link.failure.subject",
        application_name: t("app.title"),
        environment_name: environment_mailer_prefix
      )
    )
  end
end
