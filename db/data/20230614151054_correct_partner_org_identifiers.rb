# Run me with `rails runner db/data/20230614151054_correct_partner_org_identifiers.rb`

# Two partner org identifiers need correcting, as per this Zendesk ticket https://dxw.zendesk.com/agent/tickets/17993.
# This is a one-off task.

changes = [
  {
    existing_partner_organisation_identifier: "_ES/X014088/1",
    new_partner_organisation_identifier: "ES/X014088/1"
  },
  {
    existing_partner_organisation_identifier: "_ES/X014037/1",
    new_partner_organisation_identifier: "ES/X014037/1"
  }
]

changes.each do |change|
  activity = Activity.find_by(partner_organisation_identifier: change.fetch(:existing_partner_organisation_identifier))
  puts "BEFORE: Activity #{activity.id} initially has partner organisation identifier: #{activity.partner_organisation_identifier}"

  activity.partner_organisation_identifier = change.fetch(:new_partner_organisation_identifier)
  activity.save!
  activity.reload

  puts "AFTER: Activity #{activity.id} now has partner organisation identifier: #{activity.partner_organisation_identifier}"
end
