# Run me with `rails runner db/data/20210823135218_set_nil_policy_markers_to_default.rb`

[
  "gender",
  "climate_change_adaptation",
  "climate_change_mitigation",
  "biodiversity",
  "desertification",
  "disability",
  "disaster_risk_reduction",
  "nutrition",
].each do |policy_marker_category|
  key = "policy_marker_#{policy_marker_category}"
  Activity.where("#{key}": nil).update_all("#{key}": "not_assessed")
end
