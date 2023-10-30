class AddIsNonOdaToReport < ActiveRecord::Migration[6.1]
  def up
    add_column :reports, :is_non_oda, :boolean

    ispf = Activity.by_roda_identifier("ISPF")
    Report.where(fund_id: ispf.id).update_all(is_non_oda: true) unless ispf.blank?
  end

  def down
    remove_column :reports, :is_non_oda
  end
end
