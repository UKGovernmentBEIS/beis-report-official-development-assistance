# frozen_string_literal: true

class Staff::TransactionsController < Staff::BaseController
  include Secured

  def new
    @activity = Activity.find(activity_id)
    @transaction = Transaction.new
    @transaction.activity = @activity

    authorize @transaction
  end

  def create
    @activity = Activity.find(activity_id)
    authorize @activity

    result = CreateTransaction.new(activity: @activity)
      .call(attributes: transaction_params)
    @transaction = result.object

    if result.success?
      flash[:notice] = I18n.t("form.transaction.create.success")
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

    @activity = Activity.find(activity_id)
    result = UpdateTransaction.new(transaction: @transaction)
      .call(attributes: transaction_params)

    if result.success?
      flash[:notice] = I18n.t("form.transaction.update.success")
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
end
