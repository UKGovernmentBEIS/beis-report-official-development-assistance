require "csv-safe"

namespace :activities do
  task annual_fund_impact_metrics: :environment do |_task, args|
    desc "Generates a CSV file of Activities that will be used to pre-populate an annual
          collaborative spreadsheet of fund impact metrics"

    financial_years = args.to_a

    if financial_years.empty?
      abort "Please provide at least one financial year, e.g. rake 'activities:annual_fund_impact_metrics[2022,2023]'"
    end

    output_path = "tmp/annual_fund_impact_metrics"
    FileUtils.mkdir_p(output_path)

    level_c_orgs = [
      "Connected Places Catapult",
      "Energy Systems Catapult",
      "Offshore Renewable Energy Catapult",
      "National Physics Laboratory",
      "UK Atomic Energy Authority"
    ]

    excluded_statuses = %w[
      delivery
      agreement_in_place
      open_for_applications
      stopped
      planned
    ]

    activities = Activity
      .joins(:organisation)
      .where(
        "(organisations.name IN (:level_c_orgs) AND activities.level = 'project') OR " \
          "(organisations.name NOT IN (:level_c_orgs) AND activities.level = 'third_party_project')",
        level_c_orgs: level_c_orgs
      )
      .where(id: Actual
        .where(financial_year: financial_years)
        .pluck(:parent_activity_id)
        .uniq)
      .where.not(programme_status: excluded_statuses)
      .select(
        "activities.title",
        "activities.roda_identifier",
        "activities.partner_organisation_identifier",
        "activities.programme_status",
        "activities.level",
        "activities.source_fund_code",
        "organisations.name AS organisation_name",
        "activities.id"
      ).order("organisations.name")

    headers = [
      "Partner Organisation name",
      "Activity name",
      "RODA ID",
      "Partner Organisation ID",
      "Fund",
      "Status",
      "Level"
    ]

    activities.group_by(&:organisation_name).each do |organisation_name, org_activities|
      csv_path = File.join(
        output_path,
        "#{organisation_name.parameterize}_#{financial_years.join("-")}.csv"
      )

      CSVSafe.open(csv_path, "wb") do |csv|
        csv << headers

        org_activities.each do |activity|
          partner_organisation_name = activity.organisation_name
          activity_title = activity.title
          roda_identifier = activity.roda_identifier
          partner_organisation_identifier = activity.partner_organisation_identifier
          fund_name = activity.source_fund.name
          status = I18n.t("activity.programme_status.#{activity.programme_status}")
          level = I18n.t("table.body.activity.level.#{activity.level}")

          csv << [
            partner_organisation_name,
            activity_title,
            roda_identifier,
            partner_organisation_identifier,
            fund_name,
            status,
            level
          ]
        end
      end
    end
  end
end
