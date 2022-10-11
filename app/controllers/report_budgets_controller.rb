# frozen_string_literal: true

class ReportBudgetsController < BaseController
  include Secured
  include Reports::Breadcrumbed

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    prepare_default_report_trail @report

    @report_presenter = ReportPresenter.new(@report)
    budgets_for_this_report = Budget.where(report: @report)

    @budgets = budgets_for_this_report.map { |activity| BudgetPresenter.new(activity) }

    render "reports/budgets"
  end
end
