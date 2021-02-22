class RemoveIngestedFromActivity < ActiveRecord::Migration[6.0]
  def change
    remove_column :activities, :ingested
  end
end
