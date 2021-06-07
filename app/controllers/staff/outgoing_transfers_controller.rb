class Staff::OutgoingTransfersController < Staff::BaseController
  include Transfers

  helper_method :destination_roda_identifier, :source_activity

  def transfer_model
    OutgoingTransfer
  end

  def source_activity
    @source_activity ||= Activity.find(params[:activity_id])
  end

  def destination_roda_identifier
    @transfer.destination_roda_identifier || params.dig(transfer_type, :destination_roda_identifier)
  end

  def destination_activity
    @destination_activity ||= Activity.by_roda_identifier(destination_roda_identifier)
  end

  private

  def can_create_transfer?
    authorize source_activity, :create_transfer?
  end

  def transfer_params
    params.require(transfer_type)
      .permit(
        :financial_quarter,
        :financial_year,
        :value,
        :source_id,
        :destination_roda_identifier,
      )
  end
end
