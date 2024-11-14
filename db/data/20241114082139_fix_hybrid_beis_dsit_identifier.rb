# Require me in the console with `require Rails.root + "db/data/20241114082139_fix_hybrid_beis_dsit_identifier.rb"`
# then run me with `FixHybridBeisDsitIdentifier.new.migrate!`
#
# Description:
#
# For every Activity where `previous_identifier` is NOT nil
# When the `previous_identifier` starts "GB-GOV-13" AND `transparency_identifier` starts "GB-GOV-26"
# Then set `transparency_identifier` to start "GB-GOV-13"
# AND set `previous_identifier` to nil
# AND set hybrid_beis_dsit_activity to true.
#
class FixHybridBeisDsitIdentifier
  attr_reader :target, :updated

  def initialize
    @target = 0
    @updated = 0
  end

  def migrate!
    target_activities.each do |activity|
      fix_activity(activity)
    end

    puts "Total target activities: #{@target}"
    puts "Total updated activities: #{@updated}"

    true
  end

  def target_activities
    activities = Activity.where.not(previous_identifier: nil).select do |activity|
      identifier_starts_with_beis(activity.previous_identifier) &&
        identifier_starts_with_dsit(activity.transparency_identifier)
    end

    @target = activities.count
    activities
  end

  def fix_activity(activity)
    puts "Updating activity id #{activity.id} with IATI ID: #{activity.transparency_identifier} and Previous IATI ID: #{activity.previous_identifier}"

    activity.update!(
      transparency_identifier: activity.previous_identifier,
      previous_identifier: nil,
      hybrid_beis_dsit_activity: true
    )

    @updated += 1
    puts "Activity Updated!"
  end

  def identifier_starts_with_beis(identifier)
    return if identifier.nil?

    identifier.slice(0, 9).eql?("GB-GOV-13")
  end

  def identifier_starts_with_dsit(identifier)
    return if identifier.nil?

    identifier.slice(0, 9).eql?("GB-GOV-26")
  end
end
