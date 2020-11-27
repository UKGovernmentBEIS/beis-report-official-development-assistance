class AddCountryDeliveryPartnersToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :country_delivery_partners, :string, array: true
  end
end
