class AddIspfOdaAndNonOdaPartnerCountriesToActivities < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :ispf_oda_partner_countries, :string, array: true
    add_column :activities, :ispf_non_oda_partner_countries, :string, array: true
  end
end
