# frozen_string_literal: true

class Staff::ActivityFinancialsController < Staff::BaseController
  include Secured

  def show
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    @transactions = policy_scope(Transaction).where(parent_activity: @activity).order("date DESC")
    @budgets = policy_scope(Budget).where(parent_activity: @activity).order("period_start_date DESC")
    @planned_disbursements = policy_scope(PlannedDisbursement).where(parent_activity: @activity).order("period_start_date DESC")

    @transaction_presenters = @transactions.includes(:parent_activity).map { |transaction| TransactionPresenter.new(transaction) }
    @budget_presenters = @budgets.includes(:parent_activity).map { |budget| BudgetPresenter.new(budget) }
    @planned_disbursement_presenters = @planned_disbursements.map { |planned_disbursement| PlannedDisbursementPresenter.new(planned_disbursement) }
    @implementing_organisation_presenters = @activity.implementing_organisations.map { |implementing_organisation| ImplementingOrganisationPresenter.new(implementing_organisation) }
    render "staff/activities/financials"
  end
end
