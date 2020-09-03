class CorrectTransparencyIdentifiers < ActiveRecord::Migration[6.0]
  def up
    Activity.transaction do
      Activity.update_all(transparency_identifier: nil)

      Activity.lock.where.not(roda_identifier_compound: nil).find_each do |activity|
        activity.transparency_identifier = [
          activity.reporting_organisation.iati_reference,
          activity.roda_identifier_compound.gsub(/[^a-z0-9-]+/i, "-"),
        ].join("-")

        activity.save!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
