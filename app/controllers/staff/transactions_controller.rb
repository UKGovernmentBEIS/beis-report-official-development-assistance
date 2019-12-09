# frozen_string_literal: true

class Staff::TransactionsController < Staff::BaseController
  include Secured
  include DateHelper

  def new
    @transaction = policy_scope(Transaction).new
    @fund = Fund.find(fund_id)
    authorize @transaction
  end

  def create
    @transaction = policy_scope(Transaction).new(transaction_params)
    authorize @transaction

    @fund = Fund.find(fund_id)
    @transaction.update(fund: @fund)
    @transaction.assign_attributes(transaction_params)
    @transaction.date = format_date(date)

    if @transaction.save
      flash[:notice] = I18n.t("form.transaction.create.success")
      redirect_to organisation_fund_path(@fund.organisation, @fund)
    else
      render :new
    end
  end

  private

  def date
    date_fields = params.require(:transaction).permit("date(3i)", "date(2i)", "date(1i)")
    {day: date_fields["date(3i)"], month: date_fields["date(2i)"], year: date_fields["date(1i)"]}
  end

  def transaction_params
    params.require(:transaction).permit(
      :reference,
      :description,
      :transaction_type,
      :currency,
      :value,
      :disbursement_channel
    )
  end

  def fund_id
    params[:fund_id]
  end
end
