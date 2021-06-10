class OutgoingTransferPolicy < ApplicationPolicy
  include TransferPolicy

  def target_activity
    record.source
  end
end
