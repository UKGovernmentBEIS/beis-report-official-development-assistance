# Run me with:
#
# `rails runner db/data/20220715170000_use_graduated_country_as_benefitting_country.rb`
#
# Since https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/commit/fe68bc2463512c73b6f594b9bc1d19890dbb6b13
# Sept 2021, when adding or updating an activity via the bulk upload mechanism
# it's not been possible to associate a "graduated" country with an
# activity as an entry in `benefitting_countries`. However, there are some historic
# activities (they have `actual_end_dates`) which are missing a benefitting country
# which was valid at the time it was active.
#
# See https://dxw.zendesk.com/agent/tickets/16109 for more details.
#
# For example, GCRF-AH_C_LGI-2016AH/P009158/1 was active between 01-Nov-2016 and 30-Jun-2017.
# At that time Chile was a valid benefitting country. However, the historic activity
# was added to RODA last year (15-Jun-2021) and by that later date Chile was no
# longer valid for ODA -- it had the status "graduated".
#
# In this migration we add "graduated" countries to the list of benefitting countries
# in the case of 4 historic activities.
#
# In the case of 3 of these activities, we replace the existing benefitting country, because
# BEIS have informed us that it was only added to pass RODA validation, and the "graduated"
# country is the only benefitting country.

replacement_changes = [
  {
    roda_identifier: "NF-EP_CH_PA2-2015-EDBEP2K",
    graduated_country_name: "Chile",
    graduated_country_code: "CL"
  },
  {
    roda_identifier: "NF-EP_CH_PA2-2015-H8W5TMG",
    graduated_country_name: "Chile",
    graduated_country_code: "CL"
  },
  {
    roda_identifier: "GCRF-AH_C_LGI-2016AH/P009158/1",
    graduated_country_name: "Chile",
    graduated_country_code: "CL"
  }
]

additive_changes = [
  {
    roda_identifier: "GCRF-NE_17A_Grow-2016NE/P021050/1",
    graduated_country_name: "Seychelles",
    graduated_country_code: "SC"
  }
]

additive_changes.each do |change|
  activity = Activity.find_by!(roda_identifier: change.fetch(:roda_identifier))
  puts "BEFORE: Activity #{activity.roda_identifier} initially has benefitting countries: #{activity.benefitting_countries}"

  activity.benefitting_countries << change.fetch(:graduated_country_code)
  activity.save!
  activity.reload

  puts "AFTER: Activity #{activity.roda_identifier} now has benefitting countries: #{activity.benefitting_countries}"
end

replacement_changes.each do |change|
  activity = Activity.find_by!(roda_identifier: change.fetch(:roda_identifier))
  puts "BEFORE: Activity #{activity.roda_identifier} initially has benefitting countries: #{activity.benefitting_countries}"

  activity.benefitting_countries = [change.fetch(:graduated_country_code)]
  activity.save!
  activity.reload

  puts "AFTER: Activity #{activity.roda_identifier} now has benefitting countries: #{activity.benefitting_countries}"
end
