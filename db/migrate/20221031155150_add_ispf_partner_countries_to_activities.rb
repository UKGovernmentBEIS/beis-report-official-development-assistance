class AddIspfPartnerCountriesToActivities < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :ispf_partner_countries, :string, array: true
  end
end
