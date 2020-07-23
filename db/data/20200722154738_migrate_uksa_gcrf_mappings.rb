require "csv"

class MigrateUksaGcrfMappings < ActiveRecord::Migration[6.0]
  def up
    csv = CSV.read("#{Rails.root}/vendor/data/iati_activity_to_parent_mappings/GB-GOV-EA31.csv", headers: [:identifier, :parent_identifier]).drop(1)

    Activity.transaction do
      csv.each do |row|
        activity = Activity.project.find_by!(identifier: row[:identifier])
        activity.level = :third_party_project
        activity.parent = Activity.project.find_by!(identifier: row[:parent_identifier])
        activity.save!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
