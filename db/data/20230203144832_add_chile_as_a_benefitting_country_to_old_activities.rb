# Run me with `rails runner db/data/20230203144832_add_chile_as_a_benefitting_country_to_old_activities.rb`

# We received a support query (https://dxw.zendesk.com/agent/tickets/17565)
# regarding two old activities that should have Chile as a benefitting country,
# but don't.
#
# Chile is no longer available in the UI as it is no longer an eligible
# benefitting country, however, it was at the time the activities were active.

chile_country_code = "CL"
roda_identifiers = %w[
  OODA-ESRC-JZQR3SF-RJS83ZY-VW52C2J
  OODA-ESRC-JZQR3SF-RJS83ZY
]

activities = Activity.where(roda_identifier: [roda_identifiers])

activities.each do |activity|
  puts "BEFORE: Activity #{activity.roda_identifier} initially has benefitting countries: #{activity.benefitting_countries}"

  activity.update_attribute(
    :benefitting_countries, activity.benefitting_countries.push(chile_country_code)
  )

  activity.reload

  puts "AFTER: Activity #{activity.roda_identifier} now has benefitting countries: #{activity.benefitting_countries}"
end
