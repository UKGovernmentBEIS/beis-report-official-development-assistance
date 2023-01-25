# Run me with `rails runner db/data/20230119161512_move_partner_countries_to_new_fields.rb`

activities = Activity.where.not(ispf_partner_countries: nil)

puts "Activities with ISPF partner countries: #{activities.count}"

oda_activities = activities.where(is_oda: true)
non_oda_activities = activities.where(is_oda: false)

puts "  ODA: #{oda_activities.count}"
puts "  Non-ODA: #{non_oda_activities.count}"

print "\nTransferring partner countries to new fields..."

oda_activities.each do |activity|
  partner_countries = activity.ispf_partner_countries

  activity.update_columns(ispf_oda_partner_countries: partner_countries, ispf_partner_countries: nil)
end

non_oda_activities.each do |activity|
  partner_countries = activity.ispf_partner_countries

  activity.update_columns(ispf_non_oda_partner_countries: partner_countries, ispf_partner_countries: nil)
end

remaining_activities_with_original_field_count = Activity.where.not(ispf_partner_countries: nil).count
activities_with_oda_partner_countries_count = Activity.where.not(ispf_oda_partner_countries: nil).count
activities_with_non_oda_partner_countries_count = Activity.where.not(ispf_non_oda_partner_countries: nil).count

puts " finished!"
puts "\nActivities with:"
puts "  ISPF partner countries: #{remaining_activities_with_original_field_count}"
puts "  ISPF ODA partner countries: #{activities_with_oda_partner_countries_count}"
puts "  ISPF non-ODA partner countries: #{activities_with_non_oda_partner_countries_count}"
