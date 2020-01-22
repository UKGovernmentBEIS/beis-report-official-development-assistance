class AddActivityFieldsToFund < ActiveRecord::Migration[6.0]
  def change
    change_table :funds do |t|
      t.string :identifier, unique: true
      t.string :sector
      t.string :title
      t.text :description
      t.string :status
      t.date :planned_start_date
      t.date :planned_end_date
      t.date :actual_start_date
      t.date :actual_end_date
      t.string :recipient_region
      t.string :flow
      t.string :finance
      t.string :aid_type
      t.string :tied_status
      t.string :wizard_status
    end
  end
end
