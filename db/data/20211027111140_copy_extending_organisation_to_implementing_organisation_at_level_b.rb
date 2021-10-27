# Run me with `rails runner db/data/20211027111140_copy_extending_organisation_to_implementing_organisation_at_level_b.rb`
#
level_b_acitivities_without_implementing_organisations =
  Activity
    .includes(:extending_organisation)
    .where(level: :programme)
    .where.not(extending_organisation_id: nil)
    .select { |activity| activity.implementing_organisations.empty? }

level_b_acitivities_without_implementing_organisations.each do |activity|
  extending_organisation = activity.extending_organisation

  implementing_organisation = ImplementingOrganisation.create!(
    name: extending_organisation.name,
    reference: extending_organisation.iati_reference,
    organisation_type: extending_organisation.organisation_type,
    activity_id: activity.id
  )

  puts "Created implementing organisation #{implementing_organisation.name} for activity #{activity.roda_identifier}\n"
end
