# Run me with `rails runner db/data/20230718131711_import_ukri_level_d_budgets.rb`

# Script to add budgets to activities when those budgets cannot be added via bulk upload (for example they are for a
# level not currently handled by bulk upload).

# Re-usable if you replace `file_name` with the path to your chosen csv.
# Note that the script expects column headers of the following form: "Activity RODA ID"; "Budget amount"; "Type";
# "Financial year" The order of the columns is not sensitive.

# This script bypasses the usual budget validation required by the Budget model. This is to allow us to upload these
# budgets without the need for a report attached to each.

# Details of budgets that cannot be successfully created are logged to the terminal at the end of the script run.

require "csv"

def get_financial_year(financial_year_range)
  financial_year_range.split("-")[0]
end

def validate_budget(budget)
  budget.valid?
  report_error = budget.errors.messages[:report]
  budget.errors.messages.count == 1 && report_error.count == 1
end

file_name = "ukri_level_d_budget_upload.csv"

puts "Loading csv data from #{file_name}"

file = File.open(file_name)
budget_data = CSV.parse(file.read, headers: true)

initial_budgets_count = Budget.count

puts "There are #{initial_budgets_count} existing budgets."
puts "There are #{budget_data.count} budgets to create."

puts "Creating budgets..."

logged_unsuccessful = {}

budget_data.each do |row|
  roda_identifier = row["Activity RODA ID"]
  parent_activity = Activity.find_by(roda_identifier: roda_identifier)
  value = row["Budget amount"]
  budget_type = row["Type"]
  financial_year_range = row["Financial year"]

  budget_attributes = {
    parent_activity_id: parent_activity&.id,
    currency: parent_activity&.default_currency,
    value: value,
    budget_type: Budget.budget_types.key(Integer(budget_type, exception: false)),
    financial_year: get_financial_year(financial_year_range)
  }

  begin
    budget = Budget.new
    budget.assign_attributes(budget_attributes)
    unless validate_budget(budget)
      logged_unsuccessful[roda_identifier] = budget
      next
    end

    budget.save(validate: false)
  rescue
    budget.valid?
    logged_unsuccessful[roda_identifier] = budget
  end
end

puts "Budget creation complete."
puts "There were #{initial_budgets_count} budgets in the database before the import"
puts "There are now #{Budget.count} budgets in the database"
puts "#{Budget.count - initial_budgets_count} budgets have been imported"
puts "#{budget_data.count} budgets were supplied in CSV"

if logged_unsuccessful.size > 0
  puts "The following #{logged_unsuccessful.size} budgets could not be created and have not been saved to the database:"
  logged_unsuccessful.each do |roda_identifier, budget|
    puts "Budget for #{roda_identifier} in financial year #{budget.financial_year} was not created."
    puts "Error(s):"
    budget.errors.messages.each_key { |k| puts k }
  end
end
