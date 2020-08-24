# frozen_string_literal: true

class Staff::TransactionsController < Staff::BaseController
  include Secured

  def new
    @activity = activity
    @transaction = Transaction.new
    @transaction.parent_activity = @activity
    pre_fill_providing_organisation

    authorize @transaction
  end

  def create
    @activity = activity
    authorize @activity

    result = CreateTransaction.new(activity: @activity)
      .call(attributes: transaction_params)
    @transaction = result.object

    if result.success?
      @transaction.create_activity key: "transaction.create", owner: current_user
      flash[:notice] = t("action.transaction.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def edit
    @transaction = Transaction.find(id)
    authorize @transaction

    @activity = Activity.find(activity_id)
  end

  def update
    @transaction = Transaction.find(id)
    authorize @transaction

    @activity = activity
    result = UpdateTransaction.new(transaction: @transaction)
      .call(attributes: transaction_params)

    if result.success?
      @transaction.create_activity key: "transaction.update", owner: current_user
      flash[:notice] = t("action.transaction.update.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(
      :reference,
      :description,
      :transaction_type,
      :currency,
      :date,
      :value,
      :disbursement_channel,
      :providing_organisation_name,
      :providing_organisation_reference,
      :providing_organisation_type,
      :receiving_organisation_name,
      :receiving_organisation_reference,
      :receiving_organisation_type
    )
  end

  def activity_id
    params[:activity_id]
  end

  def id
    params[:id]
  end

  def activity
    @activity ||= Activity.find(activity_id)
  end

  private def pre_fill_providing_organisation
    @transaction.providing_organisation_name = @activity.providing_organisation.name
    @transaction.providing_organisation_type = @activity.providing_organisation.organisation_type
    @transaction.providing_organisation_reference = @activity.providing_organisation.iati_reference
  end
end
