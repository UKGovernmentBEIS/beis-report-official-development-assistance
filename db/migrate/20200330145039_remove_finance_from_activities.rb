class RemoveFinanceFromActivities < ActiveRecord::Migration[6.0]
  def change
    remove_column :activities, :finance, :string
  end
end
