# frozen_string_literal: true

class Staff::ReportTransactionsController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = @report.reportable_activities
    @total_transaction = TotalPresenter.new(transactions.sum(&:value)).value
    @grouped_transactions = transactions
      .includes([:parent_activity])
      .map { |forecast| TransactionPresenter.new(forecast) }
      .group_by { |forecast| ActivityPresenter.new(forecast.parent_activity) }

    render "staff/reports/transactions"
  end

  private

  def transactions
    @transactions ||= @report.transactions
  end
end
