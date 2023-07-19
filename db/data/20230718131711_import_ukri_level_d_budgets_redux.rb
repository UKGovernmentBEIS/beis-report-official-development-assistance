# Run me with `rails runner db/data/20230718131711_import_ukri_level_d_budgets.rb`

# Script to add budgets to activities when those budgets cannot be added via bulk upload (for example they are for a
# level not currently handled by bulk upload).

# Re-usable if you replace `file_name` with the path to your chosen csv.
# Note that the script expects column headers of the following form: "Activity RODA ID"; "Budget amount"; "Type";
# "Financial year" The order of the columns is not sensitive.

# Details of budgets that cannot be successfully created are logged to the terminal at the end of the script run.

require "csv"

def get_financial_year(financial_year_range)
  financial_year_range.split("-")[0]
end

file_name = "ukri_level_d_budget_upload_test.csv"

puts "Loading csv data from #{file_name}"

file = File.open(file_name)
budget_data = CSV.parse(file.read, headers: true)

puts "Creating budgets..."

logged_unsuccessful = []

budget_data.each do |row|
  activity_id = row["Activity RODA ID"]
  parent_activity = Activity.find_by(roda_identifier: activity_id)

  value = row["Budget amount"]
  budget_type = Budget.budget_types.key(row["Type"].to_i) # `budget_type` should be provided as `"direct"` or `"other_official"`, and this gets those keys by the database value they correspond to
  financial_year = get_financial_year(row["Financial year"])

  result = CreateBudget.new(activity: parent_activity).call(attributes: {value: value, budget_type: budget_type, financial_year: financial_year})

  raise Error unless result.success?

  puts "Budget #{result.object.id} created."
rescue
  logged_unsuccessful.push(row)
  puts "Budget for #{row["Activity RODA ID"]} in financial year #{row["Financial year"]} could not be created."
end

puts "Budget creation complete."

if logged_unsuccessful.size > 0
  puts "The following budgets could not be created and have not been saved to the database:"
  logged_unsuccessful.each do |row|
    puts "#{row["Activity RODA ID"]} in #{row["Financial year"]}"
  end
end
