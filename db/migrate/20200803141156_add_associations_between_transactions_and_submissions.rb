class AddAssociationsBetweenTransactionsAndSubmissions < ActiveRecord::Migration[6.0]
  def change
    add_reference :transactions, :submission, type: :uuid
  end
end
