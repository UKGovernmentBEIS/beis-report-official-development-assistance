class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid do |t|
      t.string :identifier, index: true
      t.string :name
      t.string :email
      t.timestamps
    end
  end
end
