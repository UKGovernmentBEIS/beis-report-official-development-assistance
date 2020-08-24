class RenameIdentifierToDeliveryPartnerIdentifier < ActiveRecord::Migration[6.0]
  def change
    rename_column :activities, :identifier, :delivery_partner_identifier
  end
end
