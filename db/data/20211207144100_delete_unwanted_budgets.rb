# Run me with `rails runner db/data/20211207144100_delete_unwanted_budgets.rb`

def find(organisation_name:, fund:, level:)
  organisation = Organisation.find_by(beis_organisation_reference: organisation_name)
  activities = Activity.where(organisation_id: organisation.id, level: level)

  if fund == "Newton"
    activities.filter do |activity|
      activity.is_newton_funded?
    end
  else
    activities.filter do |activity|
      activity.is_gcrf_funded?
    end
  end.filter do |activity|
    activity.budgets.any?
  end
end

targets = [
  {organisation_name: "AMS", fund: "Newton", level: "project"},
  {organisation_name: "RS", fund: "Newton", level: "project"},
  {organisation_name: "UKSA", fund: "GCRF", level: "third_party_project"}
]

targets.each do |target|
  results = find(target)
  puts
  puts "Finding activities matching #{target}"
  puts "#{results.count} number of activities"

  budgets_count = results.sum { |activity|
    activity.budgets.count
  }

  puts "#{budgets_count} number of budgets"
  puts

  results.each do |activity|
    puts "#{activity.roda_identifier} | #{activity.title} | #{activity.budgets.count}"
    activity.budgets.each do |budget|
      puts "#{budget.financial_year} fiancial year and #{budget.value} value"
      if budget.delete
        puts "budget deleted"
      else
        raise "could not delete"
      end
    end
  end
end
