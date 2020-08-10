class UpdateAmsGcrfIdentifiers < ActiveRecord::Migration[6.0]
  def up
    identifiers = {
      "AMS-GCRF-01" => "AMS-GCRF-Coll-RF-FLAIR",
      "AMS-GCRF-02" => "AMS-GCRF-DEL",
      "AMS-GCRF-03" => "AMS-GCRF-Coll-RF-NG",
      "AMS-GCRF-04" => "AMS-GCRF-Core-Workshops",
      "AMS-GCRF-05" => "AMS-GCRF-Coll-RF-SF",
    }

    identifiers.each_pair do |old_identifier, new_identifier|
      activity = Activity.project.find_by("identifier ILIKE ?", "%#{old_identifier}")
      new_activity = Activity.find_by("identifier ILIKE ?", new_identifier)

      next if activity.nil? || new_activity.present?

      activity.level = :programme
      activity.identifier = new_identifier
      activity.save!

      activity.update(transparency_identifier: activity.iati_identifier)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
