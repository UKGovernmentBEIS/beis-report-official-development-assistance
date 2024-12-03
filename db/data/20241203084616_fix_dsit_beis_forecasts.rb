# Require me in the console with `require Rails.root + "db/data/20241203084616_fix_dsit_beis_forecasts.rb"`
# then run me with `FixDsitBeisForecasts.new.migrate!`
#
# Description:
#
# For every Forecast where `providing_organisation_reference` is "GB-GOV-26"
# AND the `providing_organisation_name` is NOT "DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY"
# Then set `providing_organisation_name` to "DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY"
#
# Forecasts store history and should generally not be accessed directly, however we are not creating
# new ones or destroying old ones, see:
#
# https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/develop/doc/forecasts-and-versioning.md
#
# We use `unscoped` to allow direct access and `update_column` so that the `updated_at` is not
# changed, see:
#
# https://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-update_column
#
class FixDsitBeisForecasts
  DSIT_NAME = "DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY"
  DSIT_REF = "GB-GOV-26"

  attr_reader :target, :fixed

  def initialize
    @target = 0
    @fixed = 0
  end

  def migrate!
    target_forecasts.each do |forecast|
      puts "Fixing: #{forecast.id} #{forecast.providing_organisation_reference} #{forecast.providing_organisation_name}"
      fix_forecast(forecast)
      puts "Fixed!"
      @fixed += 1
    end

    puts "Target: #{@target}"
    puts "Fixed: #{@fixed}"
    true
  end

  def target_forecasts
    targets = Forecast.unscoped
      .where(providing_organisation_reference: DSIT_REF)
      .where.not(providing_organisation_name: DSIT_NAME)

    @target = targets.count
    targets
  end

  def fix_forecast(forecast)
    forecast.update_column(:providing_organisation_name, DSIT_NAME)
  end
end
