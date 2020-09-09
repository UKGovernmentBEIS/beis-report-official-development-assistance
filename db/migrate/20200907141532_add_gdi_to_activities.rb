class AddGdiToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :gdi, :string
  end
end
