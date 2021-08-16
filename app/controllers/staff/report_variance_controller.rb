# frozen_string_literal: true

class Staff::ReportVarianceController < Staff::BaseController
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
    render "staff/reports/variance"
  end
end
