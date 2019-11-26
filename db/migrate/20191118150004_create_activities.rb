class CreateActivities < ActiveRecord::Migration[6.0]
  def change
    create_table :activities, id: :uuid do |t|
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
      t.references :fund, type: :uuid
      t.timestamps
    end
  end
end
