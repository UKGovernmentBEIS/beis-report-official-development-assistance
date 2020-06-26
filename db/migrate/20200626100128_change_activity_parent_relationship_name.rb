class ChangeActivityParentRelationshipName < ActiveRecord::Migration[6.0]
  def up
    add_column :activities, :parent_id, :uuid
    Activity.transaction do
      Activity.all.each do |activity|
        activity.parent_id = activity.activity_id
        activity.save!(validate: false)
      end
    end
    add_index :activities, :parent_id
    add_foreign_key :activities, :activities, column: "parent_id", on_delete: :restrict
    remove_column :activities, :activity_id
  end

  def down
    add_column :activities, :activity_id, :uuid
    Activity.transaction do
      Activity.all.each do |activity|
        activity.activity_id = activity.parent_id
        activity.save!(validate: false)
      end
    end
    add_index :activities, :activity_id
    add_foreign_key :activities, :activities, column: "activity_id", on_delete: :restrict
    remove_column :activities, :parent_id
  end
end
