# frozen_string_literal: true

class ReportCommentsController < BaseController
  include Secured
  include HideFromBullet
  include Reports::Breadcrumbed

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    prepare_default_report_trail @report

    @report_presenter = ReportPresenter.new(@report)
    @grouped_comments = Report::GroupedCommentsFetcher.new(report: @report, user: current_user).all

    # Comments are polymorphic; Bullet doesn't like this, see commit message for details
    skip_bullet do
      render "reports/comments"
    end
  end
end
