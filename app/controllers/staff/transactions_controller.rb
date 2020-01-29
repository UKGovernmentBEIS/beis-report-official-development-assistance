# frozen_string_literal: true

class Staff::TransactionsController < Staff::BaseController
  include Secured
  include DateHelper

  def new
    @activity = Activity.find(activity_id)
    @transaction = Transaction.new
    @transaction.activity = @activity

    authorize @transaction
  end

  def create
    @activity = Activity.find(activity_id)
    @transaction = Transaction.new(transaction_params)
    @transaction.activity = @activity
    authorize @transaction

    @transaction.assign_attributes(transaction_params)
    @transaction.provider = provider
    @transaction.receiver = receiver
    @transaction.value = monetary_value
    @transaction.date = format_date(date)

    if @transaction.save
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
    @activity = Activity.find(activity_id)
    @transaction.activity = @activity
    authorize @transaction

    @transaction.assign_attributes(transaction_params)
    @transaction.provider = provider
    @transaction.receiver = receiver
    @transaction.value = monetary_value
    @transaction.date = format_date(date)

    if @transaction.save
      flash[:notice] = I18n.t("form.transaction.update.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :edit
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

  def activity_id
    params[:activity_id]
  end

  def id
    params[:id]
  end
end
