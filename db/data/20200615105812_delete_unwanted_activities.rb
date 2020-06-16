class DeleteUnwantedActivities < ActiveRecord::Migration[6.0]
  def up
    %w[ef4ccd54-2b71-4a74-a9fe-35138f8b9fff
       7fbca807-d7d5-47ef-88a8-752770bbba4a
       3692c943-d905-452d-ba24-e5f30f54f616].each do |activity_id|
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
