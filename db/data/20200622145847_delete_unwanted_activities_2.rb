class DeleteUnwantedActivities2 < ActiveRecord::Migration[6.0]
  def up
    %w[2dd2082c-645e-4a8d-8fcc-5c344b44512b
       4d8d6b48-7d59-43bc-9307-8aa5e11daa09
       f2c3a31a-257a-490d-b7c2-b5c244af0fc6].each do |activity_id|
      activity = Activity.find activity_id
      activity.destroy!
    rescue ActiveRecord::RecordNotFound
      puts "Activity #{activity_id} not found"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
