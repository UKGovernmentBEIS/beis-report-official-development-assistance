# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured

  def index
    @activities = policy_scope(Activity)
  end

  def show
    @activity = Activity.find(id)
    authorize @activity

    @activities = @activity.activities.map { |activity| ActivityPresenter.new(activity) }

    @transactions = policy_scope(Transaction).where(activity: @activity)

    respond_to do |format|
      format.html do
        @transaction_presenters = @transactions.map { |transaction| TransactionPresenter.new(transaction) }
      end
      format.xml
    end
  end

  def create
    raise NotImplementedError
  end

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
