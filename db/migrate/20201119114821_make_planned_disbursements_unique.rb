class MakePlannedDisbursementsUnique < ActiveRecord::Migration[6.0]
  def change
    change_table :planned_disbursements do |t|
      t.index [:parent_activity_id, :financial_year, :financial_quarter, :planned_disbursement_type],
        where: "report_id IS NULL",
        unique: true,
        name: "unique_type_per_unversioned_item"

      t.index [:parent_activity_id, :financial_year, :financial_quarter, :report_id],
        where: "report_id IS NOT NULL",
        unique: true,
        name: "unique_report_per_versioned_item"
    end
  end
end
