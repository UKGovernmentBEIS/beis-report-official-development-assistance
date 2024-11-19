# Run me with `rails runner db/data/20241114082139_fix_iati_reporting_org.rb`

# Require me in the console with `require Rails.root + "db/data/20241114082139_fix_hybrid_beis_dsit_identifier.rb"`
#
class FixHybridBeisDsitIdentifier
  def migrate!
    target_activities.each do |activity|
      fix_activity(activity)
    end
  end

  def target_activities
    Activity.all.select do |activity|
      other_identifier_starts_with_beis(activity.previous_identifier)
    end
  end

  def fix_activity(activity)
    activity.update!(
      transparency_identifier: activity.previous_identifier,
      previous_identifier: nil,
      hybrid_beis_dsit_activity: true
    )
  end

  def other_identifier_starts_with_beis(other_identifier)
    return if other_identifier.nil?

    other_identifier.slice(0, 9).eql?("GB-GOV-13")
  end
end
