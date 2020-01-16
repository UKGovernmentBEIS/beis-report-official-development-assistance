class CreateProgramme < ActiveRecord::Migration[6.0]
  def change
    create_table :programmes, id: :uuid do |t|
      t.string :name
      t.references :organisation, type: :uuid
      t.references :fund, type: :uuid
      t.timestamps
    end
  end
end
