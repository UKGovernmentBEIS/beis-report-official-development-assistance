# Run me with `rails runner db/data/20230612081755_set_correct_receiving_organisations.rb`
#
# As per: https://dxw.zendesk.com/agent/tickets/18138, some receiving organisations have
# been entered incorrectly. This script sets the correct ones.

replacement_changes = [
  {
    actual_identifier: "7e88d9dc-99ff-4016-9b8e-f662ec0ca7ea",
    correct_receiving_organisation: "University College London",
    receiving_organisation_type: "80"
  },
  {
    actual_identifier: "b796db3f-dd27-44f0-ae6c-d3a49ee1a00e",
    correct_receiving_organisation: "Robert Gordon University",
    receiving_organisation_type: "80"
  },
  {
    actual_identifier: "7f2c63a0-f459-4f77-b010-c969544ef325",
    correct_receiving_organisation: "King's College London",
    receiving_organisation_type: "80"
  },
  {
    actual_identifier: "8fc01a3d-38a8-492f-9ea9-21a8b9b63bab",
    correct_receiving_organisation: "University of Birmingham",
    receiving_organisation_type: "80"
  },
  {
    actual_identifier: "c2d8f1ff-8000-4673-b980-eae8ed70859b",
    correct_receiving_organisation: "University of Warwick",
    receiving_organisation_type: "80"
  },
  {
    actual_identifier: "9490fe42-41a0-465d-91dd-41fb285dd87d",
    correct_receiving_organisation: "University College London",
    receiving_organisation_type: "80"
  },
  {
    actual_identifier: "116addfd-81ab-43d9-bb7e-d9d277bd48d1",
    correct_receiving_organisation: "Queen Mary University of London",
    receiving_organisation_type: "80"
  },
  {
    actual_identifier: "2a6a0e35-1a80-492c-b817-8362d2eb83eb",
    correct_receiving_organisation: "University of Central Lancashire",
    receiving_organisation_type: "80"
  },
  {
    actual_identifier: "05259a4f-6288-4850-a5af-a6be86fab349",
    correct_receiving_organisation: "University of Glasgow",
    receiving_organisation_type: "80"
  }
]

replacement_changes.each do |change|
  actual = Actual.find(change.fetch(:actual_identifier))
  puts "BEFORE: Actual #{actual.id} initially has receiving organisation: #{actual.receiving_organisation_name}"

  actual.receiving_organisation_name = change.fetch(:correct_receiving_organisation)
  actual.receiving_organisation_type = change.fetch(:receiving_organisation_type)
  actual.save!
  actual.reload

  puts "AFTER: Actual #{actual.id} now has receiving organisation: #{actual.receiving_organisation_name}"
  puts "AFTER: Actual #{actual.id} now has organisation type: #{actual.receiving_organisation_type}"
end
