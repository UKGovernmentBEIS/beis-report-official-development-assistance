class ReportMailer < ApplicationMailer
  def activated
    @report_presenter = ReportPresenter.new(params[:report])
    @user = params[:user]

    view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
      to: @user.email,
      subject: t("mailer.report.activated.subject", application_name: t("app.title")))
  end

  def submitted
    @report_presenter = ReportPresenter.new(params[:report])
    @user = params[:user]

    view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
      to: @user.email,
      subject: t("mailer.report.submitted.subject", application_name: t("app.title")))
  end
end
