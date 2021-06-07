class Staff::OutgoingTransfersController < Staff::BaseController
  include Transfers

  def transfer_model
    OutgoingTransfer
  end

  def source_activity
    @source_activity ||= Activity.find(params[:activity_id])
  end
  private

  def can_create_transfer?
    authorize source_activity, :create_transfer?
  end

end
