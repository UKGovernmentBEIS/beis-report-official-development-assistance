# Run me with `rails runner db/data/20210929_clear_additional_benefitting_countries_where_backfilling_not_appropriate.rb`

# It seems we were over-eager in backfilling the new `Activity#benefitting_countries`
# field, in that we added all of the countries in the legacy `recipient_region` even
# when the legacy `recipient_country` field was present.
#
# Example: Activity with RODA id 'GCRF-EP_C_MS-4_2018EP/T00343X/1':
#
#     => {"recipient_region"=>"1027",
#      "recipient_country"=>"UG",
#      "intended_beneficiaries"=>nil,
#      "requires_additional_benefitting_countries"=>false,
#      "country_delivery_partners"=>[],
#      "benefitting_countries"=>["UG", "BI", "KM", "DJ", "ER", "ET",
#                                "KE", "MG", "MW", "MU", "MZ", "RW",
#                                "SO", "SS", "SD", "TZ", "ZM", "ZW"]}
#
# In this script, we find the approx 4,000 activities which are affected:
#
# - legacy `recipient_region` is present, and
# - legacy `recipient_country` is present, and
# - there are no `intended_beneficiaries`, and
# - more than 1 country is set in the new `benefitting_countries` field
#
# and set the benefitting countries field to the legacy recipient_country value.
# e.g. `["UG"]` in the example above.

finder = Activity
  .where.not(recipient_country: nil)
  .where.not(recipient_region: nil)
  .where(intended_beneficiaries: nil)
  .where("array_length(benefitting_countries, 1) > 1")

puts "Fixing up #{finder.count} activities..."

finder.each do |activity|
  activity.benefitting_countries = [activity.recipient_country]
  activity.save(validate: false)
end

puts "-> there are now #{finder.reload.count} activities still to fix"
