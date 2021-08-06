# Run me with `rails runner db/data/20210804154421_backfill_benefitting_countries.rb`

benefitting_countries_hash = Codelist.new(type: "intended_beneficiaries").list
region_to_subregion_hash = Codelist.new(type: "region_to_subregion_mapping", source: "beis").list
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
    activity.save(validate: false)
  elsif activity.geography == "recipient_region"
    recipient_region = activity.recipient_region

    next if recipient_region.nil? || recipient_region == "998"

    recipient_regions = if !benefitting_countries_hash.key?(recipient_region)
      regions = [recipient_region]
      loop do
        subregions = regions.map { |r| region_to_subregion_hash.fetch(r) }.flatten

        break subregions if benefitting_countries_hash.keys.any? { |r| subregions.include?(r) }

        regions = subregions
      end
    else
      [recipient_region]
    end

    countries = recipient_regions.map { |region|
      benefitting_countries_hash.fetch(region, [])
    }.flatten

    activity.benefitting_countries = countries.map { |c| c["code"] }
    activity.save(validate: false)
  end
end

if (remaining_activities = Activity.where.not(geography: nil).where(benefitting_countries: nil)).present?
  puts "Database ID, RODA identifier, Form state, Geography, Recipient region"
  remaining_activities.each do |activity|
    puts [activity.id, activity.roda_identifier, activity.form_state, activity.geography, activity.recipient_region].join(",")
  end
end
