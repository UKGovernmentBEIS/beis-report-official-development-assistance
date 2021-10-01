# Run me with `rails runner db/data/20210930151236_intended_benefeciaries_to_benefitting_countries.rb`

# It seems we were over-eager in backfilling the new `Activity#benefitting_countries`
# field, in that we added all of the countries in the legacy `recipient_region` even
# when the legacy `intended_beneficiaries` field was present and populated with a more
# granular set of country data
#
# Example: Activity with RODA id 'GCRF-UKR_ARE_C19-Ag2020EP/V044613/1':
#
#     => {"recipient_region"=>"289",
#      "recipient_country"=>"nil",
#      "intended_beneficiaries"=>["NG", "ZA"],
#      "requires_additional_benefitting_countries"=>false,
#      "benefitting_countries"=>["PH", "IN", "KH", "CN", "KP", "ID", "LA", "MY", "MN", "TH", "TL",
#      "VN", "IR", "IQ", "JO", "LB", "SY", "PS", "YE", "AF", "BD", "BT", "MV", "MM", "NP", "PK", "LK"]
#
# In this script, we find the approx 400 activities which are affected:
#
# - legacy `recipient_region` is present, and
# - legacy `recipient_country` is empty, and
# - there are `intended_beneficiaries`, and
# - the number of countries in `benefitting_countries` is greater than those in `intended_beneficiaries`
#
# and set the benefitting countries to that of intended_beneficiaries
# e.g. `["NG", "ZA"]` in the example above.

finder = Activity
  .where.not(recipient_region: nil)
  .where(recipient_country: nil)
  .where("array_length(benefitting_countries, 1) >  array_length(intended_beneficiaries, 1)")

puts "Fixing up #{finder.count} activities..."

finder.each do |activity|
  activity.benefitting_countries = activity.intended_beneficiaries
  activity.save(validate: false)
end

puts "-> there are now #{finder.reload.count} activities still to fix"
