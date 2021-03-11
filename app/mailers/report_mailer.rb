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

    @role = if @user.organisation == @report_presenter.organisation
      :delivery_partner
    elsif @user.organisation.service_owner
      :service_owner
    end

    if @role.present?
      view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
        to: @user.email,
        subject: t("mailer.report.submitted.#{@role}.subject", application_name: t("app.title")))
    else
      raise ArgumentError, "User must either be a service owner or belong to the organisation making the report"
    end
  end

  def approved
    @report_presenter = ReportPresenter.new(params[:report])
    @user = params[:user]

    view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
      to: @user.email,
      subject: t("mailer.report.approved.subject", application_name: t("app.title")))
  end

  def awaiting_changes
    @report_presenter = ReportPresenter.new(params[:report])
    @user = params[:user]

    view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
      to: @user.email,
      subject: t("mailer.report.awaiting_changes.subject", application_name: t("app.title")))
  end
end
