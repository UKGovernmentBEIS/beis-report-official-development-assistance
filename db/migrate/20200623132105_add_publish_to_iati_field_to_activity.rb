class AddPublishToIatiFieldToActivity < ActiveRecord::Migration[6.0]
  def up
    add_column :activities, :publish_to_iati, :boolean, default: true
  end

  def down
    remove_column :activities, :publish_to_iati
  end
end
