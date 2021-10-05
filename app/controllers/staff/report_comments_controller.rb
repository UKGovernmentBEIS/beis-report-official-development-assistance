# frozen_string_literal: true

class Staff::ReportCommentsController < Staff::BaseController
  include Secured
  include Reports::Breadcrumbed

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    prepare_default_report_trail @report

    @report_presenter = ReportPresenter.new(@report)
    @grouped_comments = Report::GroupedCommentsFetcher.new(report: @report, user: current_user).all

    render "staff/reports/comments"
  end
end
