# frozen_string_literal: true

class Staff::ActivityFinancialsController < Staff::BaseController
  include Secured

  def show
    activity = Activity.find(params[:activity_id])
    authorize activity

    @transactions = policy_scope(Transaction).where(parent_activity: activity).order("date DESC")
    @budgets = policy_scope(Budget).where(parent_activity: activity).order("financial_year DESC")
    @forecasts = policy_scope(activity.latest_forecasts)

    @activity = ActivityPresenter.new(activity)
    @transaction_presenters = @transactions.includes(:parent_activity).map { |transaction| TransactionPresenter.new(transaction) }
    @budget_presenters = @budgets.includes(:parent_activity, :providing_organisation).map { |budget| BudgetPresenter.new(budget) }
    @forecast_presenters = @forecasts.map { |forecast| ForecastPresenter.new(forecast) }
    @implementing_organisation_presenters = activity.implementing_organisations.map { |implementing_organisation| ImplementingOrganisationPresenter.new(implementing_organisation) }
    @transfers = policy_scope(activity.source_transfers).map { |transfer| OutgoingTransferPresenter.new(transfer) }
  end
end
