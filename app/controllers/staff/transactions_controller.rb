# frozen_string_literal: true

class Staff::TransactionsController < Staff::BaseController
  include Secured
  include DateHelper
  include TransactionHelper

  def new
    @transaction = policy_scope(Transaction).new
    authorize @transaction

    @hierarchy = hierarchy
  end

  def create
    @transaction = policy_scope(Transaction).new(transaction_params)
    authorize @transaction

    @hierarchy = hierarchy

    @transaction.hierarchy = @hierarchy
    @transaction.assign_attributes(transaction_params)
    @transaction.provider = provider
    @transaction.receiver = receiver
    @transaction.value = monetary_value
    @transaction.date = format_date(date)

    if @transaction.save
      flash[:notice] = I18n.t("form.transaction.create.success")
      redirect_to transaction_hierarchy_path_for(transaction: @transaction)
    else
      render :new
    end
  end

  def edit
    @transaction = policy_scope(Transaction).find(id)
    authorize @transaction

    @fund = hierarchy_for(transaction: @transaction)
  end

  def update
    @transaction = policy_scope(Transaction).find(id)
    authorize @transaction

    @fund = hierarchy_for(transaction: @transaction)

    @transaction.assign_attributes(transaction_params)
    @transaction.provider = provider
    @transaction.receiver = receiver
    @transaction.value = monetary_value
    @transaction.date = format_date(date)

    if @transaction.save
      flash[:notice] = I18n.t("form.transaction.update.success")
      redirect_to transaction_hierarchy_path_for(transaction: @transaction)
    else
      render :edit
    end
  end

  def show
    @transaction = policy_scope(Transaction).find(id)
    authorize @transaction

    @activity = Activity.find_by(hierarchy_id: @transaction.hierarchy)

    @provider = Organisation.find(@transaction.provider_id)
    @receiver = Organisation.find(@transaction.receiver_id)
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
      :disbursement_channel,
    )
  end

  def provider
    @provider ||= begin
      provider_id = params.require(:transaction)[:provider_id]
      Organisation.find(provider_id) if provider_id.present?
    end
  end

  def receiver
    @receiver ||= begin
      receiver_id = params.require(:transaction)[:receiver_id]
      Organisation.find(receiver_id) if receiver_id.present?
    end
  end

  def monetary_value
    @monetary_value ||= begin
      string_value = params.require(:transaction).permit(:value)
      Monetize.parse(string_value).to_f
    end
  end

  def hierarchy
    # TODO: extend to support other hierarchy types
    if params[:fund_id]
      Fund.find(hierarchy_id)
    end
  end

  def hierarchy_id
    # TODO This won't always be fund_id, eventually we'll have other hierarchies
    params[:fund_id]
  end

  def id
    params[:id]
  end
end
