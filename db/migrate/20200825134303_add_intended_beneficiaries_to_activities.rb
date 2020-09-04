class AddIntendedBeneficiariesToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :intended_beneficiaries, :string, array: true
  end
end
