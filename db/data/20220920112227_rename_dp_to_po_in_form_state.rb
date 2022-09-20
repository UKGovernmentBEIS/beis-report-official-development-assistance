# Run me with `rails runner db/data/20220920112227_rename_dp_to_po_in_form_state.rb`

# Put your Ruby code here

activities_to_update = Activity.where(form_state: "country_delivery_partners")
total_activities_to_update = activities_to_update.count

puts "Updating #{total_activities_to_update} activities..."
activities_to_update.update_all(form_state: "country_partner_organisations")

country_partner_org_activities_count = Activity.where(form_state: "country_partner_organisations").count
puts "There are now #{country_partner_org_activities_count} activities with the new value"
