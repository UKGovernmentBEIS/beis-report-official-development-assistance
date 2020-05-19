class AddPlannedDisbursements < ActiveRecord::Migration[6.0]
  def change
    create_table :planned_disbursements, id: :uuid do |t|
      t.string :planned_disbursement_type
      t.date :period_start_date
      t.date :period_end_date
      t.decimal :value, precision: 13, scale: 2
      t.string :currency
      t.string :providing_organisation_name
      t.string :providing_organisation_type
      t.string :providing_organisation_reference
      t.string :receiving_organisation_name
      t.string :receiving_organisation_type
      t.string :receiving_organisation_reference
      t.boolean :ingested, default: false
      t.references :parent_activity, type: :uuid
      t.timestamps
    end
  end
end
