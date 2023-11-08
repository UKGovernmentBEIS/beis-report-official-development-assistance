class AddIsOdaToReports < ActiveRecord::Migration[6.1]
  def up
    add_column :reports, :is_oda, :boolean

    ispf = Activity.by_roda_identifier("ISPF")
    Report.where(fund_id: ispf.id).update_all(is_oda: false) if ispf
  end

  def down
    remove_column :reports, :is_oda
  end
end
