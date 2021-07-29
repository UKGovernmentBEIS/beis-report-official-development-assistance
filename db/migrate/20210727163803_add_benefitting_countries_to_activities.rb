class AddBenefittingCountriesToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :benefitting_countries, :string, array: true
  end
end
