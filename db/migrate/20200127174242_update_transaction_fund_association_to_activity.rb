class UpdateTransactionFundAssociationToActivity < ActiveRecord::Migration[6.0]
  def self.up
    change_table :transactions do |t|
      t.references :activity, type: :uuid
      t.remove :fund_id
    end
  end

  def self.down
    change_table :transactions do |t|
      t.references :fund, type: :uuid
      t.remove :activity_id
    end
  end
end
