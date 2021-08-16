# frozen_string_literal: true

class Staff::ActivityFinancialsController < Staff::BaseController
  include Secured
  include Activities::Breadcrumbed

  def show
    activity = Activity.find(params[:activity_id])
    authorize activity

    prepare_default_activity_trail(activity)

    @transactions = policy_scope(Transaction).where(parent_activity: activity).order("date DESC")
    @budgets = policy_scope(Budget).where(parent_activity: activity).order("financial_year DESC")
    @forecasts = policy_scope(activity.latest_forecasts)
    @refunds = policy_scope(Refund).where(parent_activity: activity).order("financial_year DESC")

    @activity = ActivityPresenter.new(activity)
    @transaction_presenters = @transactions.includes(:parent_activity).map { |transaction| TransactionPresenter.new(transaction) }
    @budget_presenters = @budgets.includes(:parent_activity, :providing_organisation).map { |budget| BudgetPresenter.new(budget) }
    @forecast_presenters = @forecasts.map { |forecast| ForecastPresenter.new(forecast) }
    @refund_presenters = @refunds.map { |forecast| RefundPresenter.new(forecast) }

    @implementing_organisation_presenters = activity.implementing_organisations.map { |implementing_organisation| ImplementingOrganisationPresenter.new(implementing_organisation) }
  end
end
