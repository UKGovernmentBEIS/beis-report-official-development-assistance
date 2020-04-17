class AddSectorCategoryToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :sector_category, :string
  end
end
