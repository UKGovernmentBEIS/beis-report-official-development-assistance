class AddIspfThemeToActivities < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :ispf_theme, :integer
  end
end
