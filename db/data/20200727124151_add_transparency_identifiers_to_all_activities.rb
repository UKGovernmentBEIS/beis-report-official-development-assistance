class AddTransparencyIdentifiersToAllActivities < ActiveRecord::Migration[6.0]
  def up
    activities = Activity.all
    activities.each do |activity|
      transparency_identifier = activity.iati_identifier
      Activity.where(id: activity.id, transparency_identifier: nil).update_all(transparency_identifier: transparency_identifier)
    end
  end

  def down
    Activity.update_all(transparency_identifier: nil)
  end
end
