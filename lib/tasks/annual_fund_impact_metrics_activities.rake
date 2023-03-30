require "csv-safe"

namespace :activities do
  task :annual_fund_impact_metrics, [:output_csv_path] => :environment do |_task, args|
    desc "Generates a CSV file of Activities that will be used to pre-populate an annual
          collaborative spreadsheet of fund impact metrics"

    csv_path = args[:output_csv_path] || "tmp/annual_fund_impact_metrics.csv"

    CSVSafe.open(csv_path, "wb") do |csv|
      activities = Activity
        .joins(:organisation)
        .includes(:organisation, :actuals)
        .where.not(programme_status: ["delivery", "agreement_in_place", "open_for_applications", "stopped", "planned"])
        .order("organisations.name, programme_status")

      # We want to exclude Activities that were completed more than two years ago. We have discussed
      # this and determined that the best way to do this is to exclude those that have no Actuals
      # reported in the last two years (including if there are no Actuals at all).
      active_activities = activities.reject do |activity|
        next unless activity.programme_status == "completed"

        activity.actuals.none? { |actual| actual.date >= 2.years.ago.to_date }
      end

      headers = ["Partner Organisation name", "Activity name", "RODA ID", "Partner Organisation ID", "Status"]

      csv << headers

      active_activities.each do |activity|
        partner_organisation_name = activity.organisation.name
        activity_title = activity.title
        roda_identifier = activity.roda_identifier
        partner_organisation_identifier = activity.partner_organisation_identifier
        status = I18n.t("activity.programme_status.#{activity.programme_status}")

        csv << [partner_organisation_name, activity_title, roda_identifier, partner_organisation_identifier, status]
      end
    end
  end
end
