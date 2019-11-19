class CreateOrganisationsUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :organisations_users, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.uuid :organisation_id, null: false
      t.timestamps
    end
  end
end
