class AddOdaEligibilityLeadToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :oda_eligibility_lead, :string
  end
end
