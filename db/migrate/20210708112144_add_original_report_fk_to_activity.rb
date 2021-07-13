class AddOriginalReportFkToActivity < ActiveRecord::Migration[6.1]
  def change
    change_table :activities do |t|
      t.references :originating_report, type: :uuid
    end
  end
end
