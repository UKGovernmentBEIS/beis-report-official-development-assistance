class Activity
  class Tab
    include Pundit::Authorization

    VALID_TAB_NAMES = [
      "financials",
      "other_funding",
      "details",
      "children",
      "comments",
      "transfers",
      "historical_events"
    ].freeze

    def initialize(activity:, current_user:, tab_name: "financials")
      raise ActionController::RoutingError.new("invalid tab") unless VALID_TAB_NAMES.include?(tab_name)

      @tab_name = tab_name
      @activity = ActivityPresenter.new(activity)
      @current_user = current_user

      send(tab_name)
    end

    def locals
      instance_variables.map { |attribute|
        [attribute, instance_variable_get(attribute)]
      }.to_h
    end

    def template
      "staff/activities/#{tab_name}"
    end

    private

    attr_reader :current_user, :tab_name

    def financials
      @actuals = policy_scope(Actual).where(parent_activity: @activity).order("date DESC")
      @budgets = policy_scope(Budget).where(parent_activity: @activity).order("financial_year DESC")
      @forecasts = policy_scope(@activity.latest_forecasts).includes([:parent_activity])
      @refunds = policy_scope(Refund).where(parent_activity: @activity).order("financial_year DESC")
      @adjustments = policy_scope(Adjustment).where(parent_activity: @activity).order("date DESC")

      @actual_presenters = @actuals.includes(:parent_activity).map { |actual| TransactionPresenter.new(actual) }
      @budget_presenters = @budgets.includes(:parent_activity, :providing_organisation).map { |budget| BudgetPresenter.new(budget) }
      @forecast_presenters = @forecasts.map { |forecast| ForecastPresenter.new(forecast) }
      @refund_presenters = @refunds.map { |refund| RefundPresenter.new(refund) }
      @adjustment_presenters = @adjustments.map { |adj| AdjustmentPresenter.new(adj) }

      @implementing_organisation_presenters = @activity.implementing_organisations.map { |implementing_organisation| ImplementingOrganisationPresenter.new(implementing_organisation) }
    end

    def other_funding
      @matched_efforts = @activity.matched_efforts.map { |e| MatchedEffortPresenter.new(e) }
      @external_incomes = @activity.external_incomes.map { |e| ExternalIncomePresenter.new(e) }
    end

    def details
      @activities = @activity.child_activities.order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }
      @implementing_organisation_presenters = @activity.implementing_organisations.map { |implementing_organisation| ImplementingOrganisationPresenter.new(implementing_organisation) }
    end

    def children
      @activities = @activity.child_activities.includes([:organisation, :parent]).order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }
    end

    def comments
      @comments = comments_with_includes
      @report = Report.editable_for_activity(@activity)
    end

    def comments_with_includes
      comments = Comment.for_activity(@activity)
      if current_user.partner_organisation?
        comments.includes(:commentable, :report, owner: [:organisation])
      else
        comments.includes(:commentable, :report)
      end
    end

    def transfers
      @outgoing_transfers = policy_scope(OutgoingTransfer.where(source: @activity)).map { |transfer| TransferPresenter.new(transfer) }
      @incoming_transfers = policy_scope(IncomingTransfer.where(destination: @activity)).map { |transfer| TransferPresenter.new(transfer) }
    end

    def historical_events
      @historical_events = Activity::HistoricalEventsGrouper.new(activity: @activity).call
    end
  end
end
