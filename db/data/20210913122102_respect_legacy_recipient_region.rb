# Run me with `rails runner db/data/20210913122102_respect_legacy_recipient_region.rb`

# For activities where no country was originally specified
# we need to remove the benefitting countries that we added in the 20210804154421 data migration
activities_to_update = Activity.where.not(recipient_region: nil).where(recipient_country: nil, intended_beneficiaries: nil)
total_activities_to_update = activities_to_update.count

puts "Removing benefitting_countries from #{total_activities_to_update}..."

activities_to_update.update_all(benefitting_countries: nil)
