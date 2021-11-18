class CreateOrgParticipations < ActiveRecord::Migration[6.1]
  def change
    create_table :org_participations, id: :uuid do |t|
      t.uuid :organisation_id
      t.uuid :activity_id
      t.string :role, null: false

      t.timestamps
    end
    add_index :org_participations, :organisation_id
    add_index :org_participations, :activity_id
    add_index :org_participations, :role
    add_index :org_participations, [:organisation_id, :activity_id, :role],
      unique: true, name: "idx_org_participations_on_org_and_act_and_role"
  end
end
