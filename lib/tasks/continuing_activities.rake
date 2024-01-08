require "csv-safe"

namespace :activities do
  task :continuing_activities, [:output_csv_path] => :environment do |_task, args|
    desc "Generates a CSV file of Activities that will continue under the new transparency ID"

    csv_path = args[:output_csv_path] || "tmp/continuing_activities.csv"

    CSVSafe.open(csv_path, "wb") do |csv|
      definitely_active_activities = Activity
        .joins(:organisation)
        .includes(:organisation, :actuals)
        .where.not(level: "fund")
        .where(is_oda: [nil, true])
        .where.not(programme_status: ["completed", "stopped", "cancelled", "finalisation"])
        .order("organisations.name, programme_status")

      potentially_active_activities = Activity
        .joins(:organisation)
        .includes(:organisation, :actuals)
        .where.not(level: "fund")
        .where(is_oda: [nil, true])
        .where(programme_status: ["completed", "stopped", "cancelled", "finalisation"])
        .order("organisations.name, programme_status")

      cut_off_quarter = FinancialQuarter.new(2022, 4)

      potentially_active_activities = potentially_active_activities.reject do |activity|
        activity.actuals.none? { |actual| actual.date > cut_off_quarter.end_date }
      end

      continuing_activities = definitely_active_activities + potentially_active_activities

      headers = ["Partner Organisation name", "Activity name", "RODA ID", "Transparency identifier", "Partner Organisation ID", "Status", "Level"]

      csv << headers

      continuing_activities.each do |activity|
        partner_organisation_name = activity.organisation.name
        activity_title = activity.title
        roda_identifier = activity.roda_identifier
        transparency_identifier = activity.transparency_identifier
        partner_organisation_identifier = activity.partner_organisation_identifier
        status = I18n.t("activity.programme_status.#{activity.programme_status}")
        level = I18n.t("table.body.activity.level.#{activity.level}")

        csv << [partner_organisation_name, activity_title, roda_identifier, transparency_identifier, partner_organisation_identifier, status, level]
      end
    end
  end
end
