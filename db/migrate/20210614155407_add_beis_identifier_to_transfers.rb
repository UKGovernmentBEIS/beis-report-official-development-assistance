class AddBeisIdentifierToTransfers < ActiveRecord::Migration[6.1]
  def change
    add_column :incoming_transfers, :beis_identifier, :string
    add_column :outgoing_transfers, :beis_identifier, :string
  end
end
