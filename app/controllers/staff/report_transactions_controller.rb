# frozen_string_literal: true

class Staff::ReportTransactionsController < Staff::BaseController
  include Secured
  include Reports::Breadcrumbed

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    prepare_default_report_trail @report

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = @report.reportable_activities
    @total_transaction = @report_presenter.summed_transactions
    @grouped_transactions = @report.transactions
      .includes([:parent_activity])
      .map { |forecast| TransactionPresenter.new(forecast) }
      .group_by { |forecast| ActivityPresenter.new(forecast.parent_activity) }

    render "staff/reports/transactions"
  end
end
