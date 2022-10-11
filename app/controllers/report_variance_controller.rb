# frozen_string_literal: true

class ReportVarianceController < BaseController
  include Secured
  include Reports::Breadcrumbed

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    prepare_default_report_trail @report

    @report_presenter = ReportPresenter.new(@report)

    @variance = Activity::VarianceFetcher.new(@report)

    @activities = @variance.activities
    @total = @variance.total
    render "reports/variance"
  end
end
