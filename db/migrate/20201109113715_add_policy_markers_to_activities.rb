class AddPolicyMarkersToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :policy_marker_gender, :integer
    add_column :activities, :policy_marker_climate_change_adaptation, :integer
    add_column :activities, :policy_marker_climate_change_mitigation, :integer
    add_column :activities, :policy_marker_biodiversity, :integer
    add_column :activities, :policy_marker_desertification, :integer
    add_column :activities, :policy_marker_disability, :integer
    add_column :activities, :policy_marker_disaster_risk_reduction, :integer
    add_column :activities, :policy_marker_nutrition, :integer
  end
end
