# Run me with `rails runner db/data/20210624142643_change_gcrf_strategic_area_to_alphanumeric.rb`

codelist = Codelist.new(type: "gcrf_strategic_area", source: "beis").list

codelist.each do |item|
  Activity.where(gcrf_strategic_area: [item["legacy_code"]]).update_all(
    gcrf_strategic_area: [item["code"]]
  )
end
