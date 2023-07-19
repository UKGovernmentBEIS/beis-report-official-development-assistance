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
  begin
    budget = Budget.new
    activity_id = row["Activity RODA ID"]
    parent_activity = Activity.find_by(roda_identifier: activity_id)

    budget.parent_activity = parent_activity
    budget.parent_activity_id = parent_activity.id
    budget.currency = parent_activity.organisation.default_currency

    value = row["Budget amount"]
    budget.value = value

    type = row["Type"]
    budget.budget_type = type.to_i

    financial_year_range = row["Financial year"]
    budget.financial_year = get_financial_year(financial_year_range)

    unless parent_activity.organisation.service_owner?
      budget.report = editable_report_for_activity(activity: parent_activity)
    end
  rescue
    logged_unsuccessful.push(budget)
    puts "Budget for #{budget.parent_activity_id} in financial year #{budget.financial_year} could not be created."
  end

  if budget.valid?
    budget.save!
    puts "Budget #{budget.id} created."
  else
    logged_unsuccessful.push(budget)
    puts "Budget for #{budget.parent_activity_id} in financial year #{budget.financial_year} could not be created."
  end
end

puts "Budget creation complete."

if logged_unsuccessful.size > 0
  puts "The following budgets could not be created and have not been saved to the database:"
  logged_unsuccessful.each do |budget|
    puts "Budget for #{budget.parent_activity_id} in financial year #{budget.financial_year} was not created."
  end
end
