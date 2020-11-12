class AddFstcAppliesToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :fstc_applies, :boolean
  end
end
