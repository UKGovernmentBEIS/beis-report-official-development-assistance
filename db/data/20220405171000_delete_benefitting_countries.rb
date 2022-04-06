# Run me with `rails runner db/data/20220405171000_delete_benefitting_countries.rb`

# Support ticket https://dxw.zendesk.com/agent/tickets/15636 brought it to our
# attention that there are 33 countries which have not been eligible during the period
# covered by RODA.
#
# 57 activities have included these countries in their list of #benefitting_countries.
# This is due to the mechanism where when a grouping "region" is selected, all of the
# constituent countries are added to the Activity#benefitting_countries list.
#
# In this script we:
#
# - print out information on:
#   - the 33 countries and affected activities
#   - the affected 57 activities
# - remove the invalid countries from each of the affected 57 activities'
#   #benefitting_countries list

countries_and_codes = [
  {name: "Anguilla", code: "AI"},
  {name: "Aruba", code: "AW"},
  {name: "Bahamas", code: "BS"},
  {name: "Bahrain", code: "BH"},
  {name: "Barbados", code: "BB"},
  {name: "British Virgin Islands", code: "VG"},
  {name: "Brunei Darussalam", code: "BN"},
  {name: "Cayman Islands", code: "KY"},
  {name: "Chinese Taipei", code: "TW"},
  {name: "Croatia", code: "HR"},
  {name: "Cyprus", code: "CY"},
  {name: "Falkland Islands (Malvinas)", code: "FK"},
  {name: "French Polynesia", code: "PF"},
  {name: "Gibraltar", code: "GI"},
  {name: "Hong Kong (China)", code: "HK"},
  {name: "Israel", code: "IL"},
  {name: "Korea", code: "KR"},
  {name: "Kuwait", code: "KW"},
  {name: "Macau (China)", code: "MO"},
  {name: "Malta", code: "MT"},
  {name: "Mayotte", code: "YT"},
  {name: "Netherlands Antilles", code: "AN"},
  {name: "New Caledonia", code: "NC"},
  {name: "Northern Mariana Islands", code: "MP"},
  {name: "Oman", code: "OM"},
  {name: "Qatar", code: "QA"},
  {name: "Saint Kitts and Nevis", code: "KN"},
  {name: "Saudi Arabia", code: "SA"},
  {name: "Singapore", code: "SG"},
  {name: "Slovenia", code: "SI"},
  {name: "Trinidad and Tobago", code: "TT"},
  {name: "Turks and Caicos Islands", code: "TC"},
  {name: "United Arab Emirates", code: "AE"}
]
countries = countries_and_codes.map { |i| i.fetch(:name) }
country_codes = countries_and_codes.map { |i| i.fetch(:code) }

class BenefittingCountry
  def self.find_by_name(name:)
    all.find { |country| country.name == name.strip }
  end

  def activities
    Activity.where("? = ANY(benefitting_countries)", code)
  end
end

sql_belt_and_braces = <<~SQL
  cast (activities.benefitting_countries as text[]) &&
    array['#{country_codes.join("','")}']
SQL

puts "There are #{Activity.where(sql_belt_and_braces).count} activities assigned to these countries."
puts "---"

associated_activities = {}
country_headers = %w[name code activities_count]
country_rows = []
puts "| country | code | activity_count |"
countries.each do |name|
  country = BenefittingCountry.find_by_name(name: name)
  raise "country with #{name} not found" unless country

  activities = country.activities

  puts "|#{country.name} | #{country.code} | #{activities.count}|"
  country_rows << [
    country.name,
    country.code,
    activities.count
  ]

  activities.each do |activity|
    associated_activities[activity.id] = {
      roda_id: activity.roda_identifier,
      title: activity.title,
      benefitting_country_count: activity.benefitting_countries.size,
      created_at: activity.created_at,
      updated_at: activity.updated_at
    }
  end
end

puts "There are #{countries_and_codes.count} countries"
puts
puts country_headers.join(",")
country_rows.each { |row| puts row.join(",") }
puts
puts "There are #{associated_activities.size} activities involved."
puts
puts %w[id roda_identifier title benefitting_country_count created_at updated_at].join(",")
associated_activities.each_pair do |id, attrs|
  puts "#{id},#{attrs.values.map { |value| %("#{value}") }.join(",")}"
end

puts
puts "Removing the countries from these #{associated_activities.count} activities..."

associated_activities.each_pair do |id, attrs|
  activity = Activity.find(id)
  activity.benefitting_countries = (activity.benefitting_countries - country_codes)
  activity.save!(validate: false)
end
puts "---"
puts "There are now #{Activity.where(sql_belt_and_braces).count} activities assigned to these countries."
