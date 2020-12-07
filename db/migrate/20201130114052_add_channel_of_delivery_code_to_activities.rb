class AddChannelOfDeliveryCodeToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :channel_of_delivery_code, :string
  end
end
