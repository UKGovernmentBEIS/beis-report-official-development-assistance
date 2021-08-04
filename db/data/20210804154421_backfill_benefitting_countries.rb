# Run me with `rails runner db/data/20210804154421_backfill_benefitting_countries.rb`

benefitting_countries_hash = Codelist.new(type: "intended_beneficiaries").list
activities_to_update = Activity.where.not(geography: nil).where(benefitting_countries: nil)
total_activities_to_update = activities_to_update.count

activities_to_update.each_with_index do |activity, counter|
  if ((counter + 1) % 100).zero?
    puts "#{counter + 1} of #{total_activities_to_update}"
  end

  if activity.geography == "recipient_country"
    recipient_country = activity.recipient_country
    intended_beneficiaries = activity.intended_beneficiaries || []

    activity.benefitting_countries = ([recipient_country] + intended_beneficiaries).compact.uniq
    activity.save!
  elsif activity.geography == "recipient_region"
    recipient_region = activity.recipient_region

    countries = benefitting_countries_hash.fetch(recipient_region, [])
    activity.benefitting_countries = countries.map { |c| c["code"] }
    activity.save!
  end
end

if (remaining_activities = Activity.where.not(geography: nil).where(benefitting_countries: nil)).present?
  puts "Database ID, RODA identifier, Form state, Geography, Recipient region"
  remaining_activities.each do |activity|
    puts [activity.id, activity.roda_identifier, activity.form_state, activity.geography, activity.recipient_region].join(",")
  end
end
