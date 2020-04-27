class RemoveReferenceFromTransaction < ActiveRecord::Migration[6.0]
  def change
    remove_column :transactions, :reference, :string
  end
end
