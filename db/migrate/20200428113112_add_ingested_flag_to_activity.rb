class AddIngestedFlagToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :ingested, :boolean, default: false
  end
end
