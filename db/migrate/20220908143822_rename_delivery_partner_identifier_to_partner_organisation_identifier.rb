class RenameDeliveryPartnerIdentifierToPartnerOrganisationIdentifier < ActiveRecord::Migration[6.1]
  def change
    rename_column :activities, :delivery_partner_identifier, :partner_organisation_identifier
  end
end
