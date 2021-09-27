# Run me with `rails runner db/data/20210927103536_fix_coherence_and_impact_code.rb`

Activity.where(gcrf_strategic_area: ["Clm"]).each do |activity|
  # gcrf_strategic_area is an array, so we have to be ready to preserve the rest of it untouched
  activity.gcrf_strategic_area = activity.gcrf_strategic_area - ["Clm"] + ["CIm"]
  # activities can be invalid for unrelated reasons; we still want this change to be persisted
  activity.save(validate: false)
end
