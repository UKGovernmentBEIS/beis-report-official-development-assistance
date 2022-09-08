class RenameCountryDeliveryPartnersToCountryPartnerOrganisations < ActiveRecord::Migration[6.1]
  def change
    rename_column :activities, :country_delivery_partners, :country_partner_organisations
  end
end
