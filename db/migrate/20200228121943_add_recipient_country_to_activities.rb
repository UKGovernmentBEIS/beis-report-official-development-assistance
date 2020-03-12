class AddRecipientCountryToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :recipient_country, :string
  end
end
