class AddPolymorphicHeirarchyToActivities < ActiveRecord::Migration[6.0]
  def change
    change_table :activities do |t|
      t.references :hierarchy, polymorphic: true, type: :uuid
      t.remove :fund_id
    end
  end
end
