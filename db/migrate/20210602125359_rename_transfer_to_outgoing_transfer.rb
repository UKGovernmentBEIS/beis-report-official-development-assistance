class RenameTransferToOutgoingTransfer < ActiveRecord::Migration[6.1]
  def change
    rename_table :transfers, :outgoing_transfers
  end
end
