# Run me with `rails runner db/data/20211011_reset_benefitting_countries_where_both_legacy_region_and_country_set.rb`

# It seems we were over-eager in backfilling the new `Activity#benefitting_countries`
# field, in that we added all of the countries in a legacy #recipient_region even when # #recipient_country was present. (We weren't expecting that both of these could be set.)
#
# e.g.
#
# activity = Activity.find_by(roda_identifier: 'GCRF-RFNetG-R2-GCRFNGR2\10190')
# activity.attributes.select { |k,v| k.match(/(geo)|(count)|(bene)|(region)/) }

#   => {"recipient_region"=>"1030",
#    "recipient_country"=>"NG",
#    "geography"=>"recipient_region",
#    "intended_beneficiaries"=>[],
#    "country_delivery_partners"=>[],
#    "benefitting_countries"=>
#     ["NG", "BJ", "BF", "CV", "CI", "GM", "GH", "GN", "GW", "LR", "ML", "MR",
#      "NE", "SH", "SN", "SL", "TG"]}
#
#
# To remedy, we find activities where:
#
# - legacy region is present, and
# - legacy country is present, and
# - the newly populated #benefitting_countries is greater than
#   the total legacy countries (#intended_beneficiaries.count + 1 #recipient_country )
#
#
# and we reset the new #benefitting_countries field to the content of legacy
# #recipient_country and the #intended_beneficiaries.
#
# Note: we use COALESCE() to cast null values in array fields to zero.

finder = Activity
  .where.not(recipient_region: nil)
  .where.not(recipient_country: nil)
  .where(
    "COALESCE(array_length(benefitting_countries, 1), 0) >
     COALESCE(array_length(intended_beneficiaries, 1), 0) + 1"
  )

puts "Fixing up #{finder.count} activities..."
puts "---\n"

finder.each do |activity|
  activity.benefitting_countries = activity.intended_beneficiaries + [activity.recipient_country]
  puts "#{activity.roda_identifier}: #{activity.benefitting_countries}"
  activity.save(validate: false)
end

puts "\n---"
puts "-> there are now #{finder.reload.count} activities still to fix"
