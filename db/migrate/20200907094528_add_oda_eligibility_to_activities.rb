class AddOdaEligibilityToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :oda_eligibility, :boolean, default: true
  end
end
