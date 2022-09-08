class ReportMailer < ApplicationMailer
  def activated
    @report_presenter = ReportPresenter.new(params[:report])
    @user = params[:user]
    raise_unless_active_user

    view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
      to: @user.email,
      subject: t("mailer.report.activated.subject", application_name: t("app.title"), environment_name: environment_mailer_prefix))
  end

  def submitted
    @report_presenter = ReportPresenter.new(params[:report])
    @user = params[:user]
    raise_unless_active_user

    @role = if @user.organisation == @report_presenter.organisation
      :partner_organisation
    elsif @user.organisation.service_owner?
      :service_owner
    end

    if @role.present?
      view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
        to: @user.email,
        subject: t("mailer.report.submitted.#{@role}.subject", application_name: t("app.title"), environment_name: environment_mailer_prefix))
    else
      raise ArgumentError, "User must either be a service owner or belong to the organisation making the report"
    end
  end

  def approved
    @report_presenter = ReportPresenter.new(params[:report])
    @user = params[:user]
    raise_unless_active_user

    @role = if @user.organisation == @report_presenter.organisation
      :partner_organisation
    elsif @user.organisation.service_owner?
      :service_owner
    end

    if @role.present?
      view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
        to: @user.email,
        subject: t("mailer.report.approved.#{@role}.subject", application_name: t("app.title"), environment_name: environment_mailer_prefix))
    else
      raise ArgumentError, "User must either be a service owner or belong to the organisation making the report"
    end
  end

  def awaiting_changes
    @report_presenter = ReportPresenter.new(params[:report])
    @user = params[:user]
    raise_unless_active_user

    view_mail(ENV["NOTIFY_VIEW_TEMPLATE"],
      to: @user.email,
      subject: t("mailer.report.awaiting_changes.subject", application_name: t("app.title"), environment_name: environment_mailer_prefix))
  end

  private def raise_unless_active_user
    raise ArgumentError, "User must be active to receive report-related emails" unless @user.active
  end
end
