class RemoveIspfPartnerCountriesFromActivities < ActiveRecord::Migration[6.1]
  def change
    remove_column :activities, :ispf_partner_countries, :string
  end
end
