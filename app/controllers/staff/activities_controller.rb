# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured

  def index
    @activities = policy_scope(Activity)
  end

  def show
    @activity = Activity.find(id)
    authorize @activity

    @transactions = policy_scope(Transaction).where(activity: @activity)

    respond_to do |format|
      format.html do
        @transaction_presenters = @transactions.map { |transaction| TransactionPresenter.new(transaction) }
      end
      format.xml
    end
  end

  def create
    @activity = Activity.new
    @activity.organisation = Organisation.find(organisation_id)
    authorize @activity

    @activity.wizard_status = "identifier"
    @activity.save(validate: false)

    redirect_to activity_step_path(@activity.id, @activity.wizard_status)
  end

  def id
    params[:id]
  end

  def organisation_id
    params[:organisation_id]
  end
end
