# Run me with `rails runner db/data/20220106163037_remove_actuals_from_given_activities.rb`

require "csv"
timestamp = Time.current.to_formatted_s(:number)
input_path = "tmp/activities_whose_actuals_are_to_be_deleted.csv"
summary_output_path = "tmp/activities_and_their_actuals_#{timestamp}.csv"
detail_output_path = "tmp/actuals_for_deletion_#{timestamp}.csv"

summary_output_headers = %w[
  roda_id
  activity_id
  actual_count
  pre_2022_actual_count
  earliest_period
  latest_period
  refunds_count
  adjustments_count
]

summary_output_rows = []

detail_output_headers = %w[
  roda_id
  activity_id
  actual_id
  actual_value
  actual_date
  actual_financial_quarter_and_year
]

detail_output_rows = []

ActiveRecord::Base.transaction do 
  CSV.readlines(input_path, encoding: "bom|utf-8", headers: true).each do |row|
    roda_id = row.fetch("RODA_ID")
    activity = Activity.find_by!(roda_identifier: roda_id)
    all_actuals = activity.actuals
    actuals_for_deletion = all_actuals.reject { |a| ["FQ2 2021-2022", "FQ1 2021-2022"].include?(a.financial_quarter_and_year) }

    earliest_actual = if all_actuals.any?
      all_actuals
        .min_by { |a| [a.financial_year, a.financial_quarter] }
        .financial_quarter_and_year
    else
      "-"
    end

    latest_actual = if all_actuals.any?
      all_actuals
        .max_by { |a| [a.financial_year, a.financial_quarter] }
        .financial_quarter_and_year
    else
      "-"
    end

    refunds = activity.refunds
    adjustments = activity.adjustments

    summary_output_rows << [
      roda_id,
      activity.id,
      all_actuals.count,
      actuals_for_deletion.count,
      earliest_actual,
      latest_actual,
      refunds.count,
      adjustments.count,
    ]

    actuals_for_deletion.each do |actual|
      detail_output_rows << [
        roda_id,
        activity.id,
        actual.id,
        actual.value.to_s,
        actual.date.to_s,
        actual.financial_quarter_and_year,
      ]
      puts "deleting actual #{actual.id}"
      actual.destroy!
    end
  end
end

CSV.open(summary_output_path, "w", headers: true) do |csv|
  csv << summary_output_headers
  summary_output_rows.each { |row| csv << row }
end

CSV.open(detail_output_path, "w", headers: true) do |csv|
  csv << detail_output_headers
  detail_output_rows.each { |row| csv << row }
end
