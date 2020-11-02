class ChangeOdaEligibilityType < ActiveRecord::Migration[6.0]
  def up
    add_column :activities, :oda_eligibility_integer, :integer, default: 1, null: false
    Activity.where(oda_eligibility: nil).update_all(oda_eligibility_integer: 1)
    Activity.where(oda_eligibility: true).update_all(oda_eligibility_integer: 1)
    Activity.where(oda_eligibility: false).update_all(oda_eligibility_integer: 2)
    remove_column :activities, :oda_eligibility, :boolean
    rename_column :activities, :oda_eligibility_integer, :oda_eligibility
  end

  def down
    add_column :activities, :oda_eligibility_boolean, :boolean, default: true
    Activity.where(oda_eligibility: 0).update_all(oda_eligibility_boolean: false)
    Activity.where(oda_eligibility: 1).update_all(oda_eligibility_boolean: true)
    Activity.where(oda_eligibility: 2).update_all(oda_eligibility_boolean: false)
    remove_column :activities, :oda_eligibility, :integer
    rename_column :activities, :oda_eligibility_boolean, :oda_eligibility
  end
end
