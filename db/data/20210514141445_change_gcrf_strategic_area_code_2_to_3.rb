# Run me with `rails runner db/data/20210514141445_change_gcrf_strategic_area_code_2_to_3.rb`

Activity.where("gcrf_strategic_area @> '{2}'::integer[]").each do |activity|
  gcrf_strategic_areas = activity.gcrf_strategic_area.map { |i| (i == 2) ? 3 : i }
  activity.update_column(:gcrf_strategic_area, gcrf_strategic_areas)
end
