class AddPolymorphicHierarchyToTransactions < ActiveRecord::Migration[6.0]
  def change
    change_table :transactions do |t|
      t.references :hierarchy, polymorphic: true, type: :uuid
      t.remove :fund_id
    end
  end
end
