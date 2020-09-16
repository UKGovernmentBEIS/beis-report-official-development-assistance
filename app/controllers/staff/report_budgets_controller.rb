# frozen_string_literal: true

class Staff::ReportBudgetsController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
    budgets_for_this_report = Budget.where(report: @report)

    @budgets = budgets_for_this_report.map { |activity| BudgetPresenter.new(activity) }

    render "staff/reports/budgets"
  end
end
