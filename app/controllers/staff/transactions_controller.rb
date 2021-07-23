# frozen_string_literal: true

class Staff::TransactionsController < Staff::BaseController
  include Secured

  def new
    @activity = activity
    @transaction = Transaction.new
    @transaction.parent_activity = @activity

    @report = Report.editable_for_activity(@activity)
    @transaction.financial_quarter = @report&.financial_quarter
    @transaction.financial_year = @report&.financial_year

    authorize @transaction
  end

  def create
    @activity = activity
    authorize @activity

    result = CreateTransaction.new(activity: @activity)
      .call(attributes: transaction_params)
    @transaction = result.object

    if result.success?
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
    result = UpdateTransaction.new(
      transaction: @transaction,
      user: current_user,
      report: Report.editable_for_activity(@activity)
    ).call(attributes: transaction_params)

    if result.success?
      flash[:notice] = t("action.transaction.update.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  def destroy
    @transaction = Transaction.find(id)
    authorize @transaction

    @transaction.destroy

    flash[:notice] = t("action.transaction.destroy.success")

    redirect_to organisation_activity_path(activity.organisation, activity)
  end

  private

  def transaction_params
    params.require(:transaction).permit(
      :value,
      :financial_quarter,
      :financial_year,
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
end
