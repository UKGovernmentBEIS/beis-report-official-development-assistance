class RemoveAssociationBetweenTransactionAndOrganisation < ActiveRecord::Migration[6.0]
  def change
    remove_reference :transactions, :provider, index: true
    remove_reference :transactions, :receiver, index: true
  end
end
