class AddHybridBeisDsitActivity < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :hybrid_beis_dsit_activity, :boolean, default: false
  end
end
