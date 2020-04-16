class RenameTransactionActivityIdToParentActivityId < ActiveRecord::Migration[6.0]
  def up
    add_column :transactions, :parent_activity_id, :uuid
    add_index :transactions, :parent_activity_id
    add_foreign_key :transactions, :activities, column: :parent_activity_id, on_delete: :cascade

    ActiveRecord::Base.transaction do
      Transaction.all.each do |transaction|
        transaction.parent_activity = transaction.activity
        transaction.save!
      end
    end

    remove_column :transactions, :activity_id
  end

  def down
    add_column :transactions, :activity_id, :uuid
    add_index :transactions, :activity_id
    add_foreign_key :transactions, :activities, on_delete: :cascade

    ActiveRecord::Base.transaction do
      Transaction.all.each do |transaction|
        transaction.activity = transaction.parent_activity
        transaction.save!
      end
    end

    remove_column :transactions, :parent_activity_id
  end
end
