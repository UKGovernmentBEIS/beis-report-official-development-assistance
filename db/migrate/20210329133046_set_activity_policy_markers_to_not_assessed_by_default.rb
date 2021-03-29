class SetActivityPolicyMarkersToNotAssessedByDefault < ActiveRecord::Migration[6.0]
  def change
    change_column_default :activities, :policy_marker_gender, from: nil, to: 1000
    change_column_default :activities, :policy_marker_climate_change_adaptation, from: nil, to: 1000
    change_column_default :activities, :policy_marker_climate_change_mitigation, from: nil, to: 1000
    change_column_default :activities, :policy_marker_biodiversity, from: nil, to: 1000
    change_column_default :activities, :policy_marker_desertification, from: nil, to: 1000
    change_column_default :activities, :policy_marker_disability, from: nil, to: 1000
    change_column_default :activities, :policy_marker_disaster_risk_reduction, from: nil, to: 1000
    change_column_default :activities, :policy_marker_nutrition, from: nil, to: 1000
  end
end
