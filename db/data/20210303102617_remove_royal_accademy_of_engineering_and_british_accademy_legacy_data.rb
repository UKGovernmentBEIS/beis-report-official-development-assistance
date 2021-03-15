# Run me with `rails runner db/data/20210303102617_remove_royal_accademy_of_engineering_and_british_accademy_legacy_data.rb`
#
# Put your Ruby code here
def remove_all_data_set_for_organisation_id(organisation_id)
  # collect all activities
  activities = Activity.where(organisation_id: organisation_id).or(Activity.where(extending_organisation_id: organisation_id))
  activity_ids = activities.pluck(:id)

  # destroy all transactions
  transactions = Transaction.where(parent_activity_id: activity_ids)
  transactions.destroy_all

  # destroy all forecasts
  forecasts = PlannedDisbursement.where(parent_activity_id: activity_ids)
  forecasts.destroy_all

  # destroy all budgets
  budgets = Budget.where(parent_activity_id: activity_ids)
  budgets.destroy_all

  # destroy all activites
  activities.destroy_all
end

royal_accademy_of_engineering = Organisation.find_by(name: "Royal Academy of Engineering", iati_reference: "GB-CHC-293074")
british_accademy = Organisation.find_by(name: "British Academy", iati_reference: "GB-COH-RC000053")

raise "Could not locate Royal Academy of Engineering or British Academy, both are required to run" if british_accademy.nil? || royal_accademy_of_engineering.nil?
organisation_ids = [royal_accademy_of_engineering.id, british_accademy.id]
organisation_ids.each { |id| remove_all_data_set_for_organisation_id(id) }
