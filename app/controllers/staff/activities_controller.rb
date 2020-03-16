# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured

  def index
    @activities = policy_scope(Activity)
  end

  def show
    @activity = Activity.find(id)
    authorize @activity

    @activities = @activity.activities.order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }

    @transactions = policy_scope(Transaction).where(activity: @activity).order("date DESC")
    @budgets = policy_scope(Budget).where(activity: @activity)

    respond_to do |format|
      format.html do
        @transaction_presenters = @transactions.map { |transaction| TransactionPresenter.new(transaction) }
        @budget_presenters = @budgets.map { |budget| BudgetPresenter.new(budget) }
        @implementing_organisation_presenters = @activity.implementing_organisations.map { |implementing_organisation| ImplementingOrganisationPresenter.new(implementing_organisation) }
      end
      format.xml do |_format|
        @activity_xml_presenter = ActivityXmlPresenter.new(@activity)
        response.headers["Content-Disposition"] = "attachment; filename=\"#{@activity_xml_presenter.iati_identifier}.xml\""
      end
    end
  end

  def create
    raise NotImplementedError
  end

  private

  def id
    params[:id]
  end

  def organisation_id
    params[:organisation_id]
  end

  def fund_id
    params[:fund_id]
  end
end
