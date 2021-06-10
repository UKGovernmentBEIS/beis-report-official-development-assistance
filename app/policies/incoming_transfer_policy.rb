class IncomingTransferPolicy < ApplicationPolicy
  include TransferPolicy

  def target_activity
    record.destination
  end
end
