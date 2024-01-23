namespace :activities do
  task continuing_activities: :environment do
    dry_run = ENV.fetch("DRY_RUN", "true").downcase
    unless dry_run == "false"
      puts "Performing a dry run of the script. No activities, actuals, or forecasts will actually be changed. Pass DRY_RUN=false to the task to do any changes."
    end

    skip_validation = ENV.fetch("SKIP_VALIDATION", "").downcase
    if skip_validation == "true"
      puts "Validations will be skipped. Activities, actuals, and forecasts will be changed in place."
    end

    continuing_activities = Export::ContinuingActivities.new.activities
    continuing_activities.each do |activity|
      puts "\n Activity #{activity.roda_identifier}"

      original_transparency_identifier = activity.transparency_identifier.to_s
      updated_previous_identifier = original_transparency_identifier
      updated_transparency_identifier = original_transparency_identifier.sub(/\AGB-GOV-13/, "GB-GOV-26")

      if original_transparency_identifier == updated_transparency_identifier
        puts "NO CHANGE: transparency_identifier=#{original_transparency_identifier}"
      elsif dry_run == "false"
        if skip_validation == "true"
          activity.update_columns(
            previous_identifier: updated_previous_identifier,
            transparency_identifier: updated_transparency_identifier,
            updated_at: Time.current
          )
        elsif activity.update(
          previous_identifier: updated_previous_identifier,
          transparency_identifier: updated_transparency_identifier
        )
          activity.reload
          puts "UPDATED: transparency_identifier=#{activity.transparency_identifier} previous_identifier=#{activity.previous_identifier}"
        else
          puts "ERROR: #{activity.errors.messages.inspect}"
        end
      end

      activity_actuals = activity.actuals.where(providing_organisation_reference: "GB-GOV-13")
      puts "Eligible actuals: #{activity_actuals.count}"

      if dry_run == "false"
        activity_actuals.each do |actual|
          if skip_validation == "true"
            actual.update_columns(
              providing_organisation_reference: "GB-GOV-26",
              updated_at: Time.current
            )
          elsif actual.update(providing_organisation_reference: "GB-GOV-26")
            puts "Actual #{actual.id} UPDATED"
          else
            puts "Actual #{actual.id} ERROR: #{actual.errors.messages.inspect}"
          end
        end
      end

      activity_forecasts = Forecast.unscoped.where(parent_activity_id: activity.id, providing_organisation_reference: "GB-GOV-13")
      puts "Eligible forecasts: #{activity_forecasts.count}"

      if dry_run == "false"
        activity_forecasts.each do |forecast|
          if skip_validation == "true"
            forecast.update_columns(
              providing_organisation_reference: "GB-GOV-26",
              updated_at: Time.current
            )
          elsif forecast.update(providing_organisation_reference: "GB-GOV-26")
            puts "Forecast #{forecast.id} UPDATED"
          else
            puts "Forecast #{forecast.id} ERROR: #{forecast.errors.messages.inspect}"
          end
        end
      end
    end
  end
end
