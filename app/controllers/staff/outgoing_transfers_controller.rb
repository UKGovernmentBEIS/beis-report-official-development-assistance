class Staff::OutgoingTransfersController < Staff::BaseController
  include Transfers

  def transfer_model
    OutgoingTransfer
  end
end
