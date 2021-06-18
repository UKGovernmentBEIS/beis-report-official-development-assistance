class Staff::IncomingTransfersController < Staff::BaseController
  include Transfers

  helper_method :source_roda_identifier, :destination_activity

  def transfer_model
    IncomingTransfer
  end

  def destination_activity
    @destination_activity ||= Activity.find(params[:activity_id])
  end

  def source_roda_identifier
    @transfer.source_roda_identifier || params.dig(transfer_type, :source_roda_identifier)
  end

  def source_activity
    @source_activity ||= Activity.by_roda_identifier(source_roda_identifier)
  end

  private

  def can_create_transfer?
    authorize destination_activity, :create_transfer?
  end

  def transfer_params
    params.require(transfer_type)
      .permit(
        :financial_quarter,
        :financial_year,
        :value,
        :destination_id,
        :source_roda_identifier,
        :beis_identifier,
      )
  end

  def target_activity
    destination_activity
  end
end
