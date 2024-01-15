class ChangeTransparencyIdentifier < ActiveRecord::Migration[6.1]
  def up
    continuing_activities = Export::ContinuingActivities.new.activities

    continuing_activities.each do |activity|
      original_previous_identifier = activity.previous_identifier.to_s
      original_transparency_identifier = activity.transparency_identifier.to_s
      updated_previous_identifier = original_transparency_identifier
      updated_transparency_identifier = original_transparency_identifier.sub(/\AGB-GOV-13/, "GB-GOV-26")

      if original_transparency_identifier == updated_transparency_identifier
        Rails.logger.info("Activity #{activity.roda_identifier} NO CHANGE: transparency_identifier=#{original_transparency_identifier}")
      elsif activity.update(
        previous_identifier: updated_previous_identifier,
        transparency_identifier: updated_transparency_identifier
      )
        message = "Activity #{activity.roda_identifier} UPDATED: previous_identifier=#{updated_previous_identifier} transparency_identifier=#{updated_transparency_identifier}"
        if original_previous_identifier
          message += " original previous_identifier=#{original_previous_identifier}"
        end
        Rails.logger.info(message)
      else
        Rails.logger.error("Activity #{activity.roda_identifier} UPDATE FAILED")
      end

      activity_actuals = activity.actuals.where(providing_organisation_reference: "GB-GOV-13")
      if activity_actuals.any?
        Rails.logger.info("Activity #{activity.roda_identifier}: Updating #{activity_actuals.count} actuals")

        activity_actuals.each do |actual|
          unless actual.update(providing_organisation_reference: "GB-GOV-26")
            Rails.logger.error("Activity #{activity.roda_identifier}: FAILED to update an actual: #{actual.id}")
          end
        end
      end

      activity_forecasts = Forecast.unscoped.where(parent_activity_id: activity.id, providing_organisation_reference: "GB-GOV-13")
      if activity_forecasts.any?
        Rails.logger.info("Activity #{activity.roda_identifier}: Updating #{activity_forecasts.count} forecasts")

        activity_forecasts.each do |forecast|
          unless forecast.update(providing_organisation_reference: "GB-GOV-26")
            Rails.logger.error("Activity #{activity.roda_identifier}: FAILED to update a forecast: #{forecast.id}")
          end
        end
      end
    end
  end

  def down
    activities_to_restore = Export::ContinuingActivities.new.activities

    activities_to_restore.each do |activity|
      if activity.transparency_identifier
        activity.update(
          previous_identifier: nil,
          transparency_identifier: activity.transparency_identifier.sub(/\AGB-GOV-26/, "GB-GOV-13")
        )
      end

      activity.actuals.where(providing_organisation_reference: "GB-GOV-26").each do |actual|
        actual.update(providing_organisation_reference: "GB-GOV-13")
      end

      Forecast.unscoped.where(parent_activity_id: activity.id, providing_organisation_reference: "GB-GOV-26").each do |forecast|
        forecast.update(providing_organisation_reference: "GB-GOV-13")
      end
    end
  end
end
