# Run me with `rails runner db/data/20210804154421_backfill_benefitting_countries.rb`

benefitting_countries_hash = Codelist.new(type: "intended_beneficiaries").list
region_to_subregion_hash = Codelist.new(type: "region_to_subregion_mapping", source: "beis").list
activities_to_update = Activity.where.not(geography: nil).where(benefitting_countries: nil)
total_activities_to_update = activities_to_update.count

activities_to_update.each_with_index do |activity, counter|
  if ((counter + 1) % 100).zero?
    puts "#{counter + 1} of #{total_activities_to_update}"
  end

  # We want all the stored information:
  # - recipient country
  # - intended beneficiaries
  # - countries belonging to the recipient region
  # regardless of whether the geography is recipient_country or recipient_region

  recipient_country = activity.recipient_country
  intended_beneficiaries = activity.intended_beneficiaries || []

  recipient_region = activity.recipient_region
  region_countries = []
  unless recipient_region.nil? || recipient_region == "998"
    recipient_regions = if !benefitting_countries_hash.key?(recipient_region)
      # We want to collect all the countries in the supra-region, by adding up the subregions' countries
      regions = [recipient_region]
      loop do
        subregions = regions.map { |r| region_to_subregion_hash.fetch(r) }.flatten

        break subregions if benefitting_countries_hash.keys.any? { |r| subregions.include?(r) }

        regions = subregions
      end
    else
      [recipient_region]
    end

    region_countries = recipient_regions.map { |region|
      benefitting_countries_hash.fetch(region, [])
    }.flatten.map { |c| c["code"] }
  end

  benefitting_countries = ([recipient_country] + intended_beneficiaries + region_countries).compact.uniq
  activity.benefitting_countries = benefitting_countries if benefitting_countries.present?
  activity.save(validate: false)
end

if (remaining_activities = Activity.where.not(geography: nil).where(benefitting_countries: nil)).present?
  puts "Database ID, RODA identifier, Form state, Geography, Recipient region"
  remaining_activities.each do |activity|
    puts [activity.id, activity.roda_identifier, activity.form_state, activity.geography, activity.recipient_region].join(",")
  end
end
