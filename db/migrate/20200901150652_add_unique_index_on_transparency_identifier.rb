class AddUniqueIndexOnTransparencyIdentifier < ActiveRecord::Migration[6.0]
  def change
    change_table :activities do |t|
      t.index [:transparency_identifier], unique: true
    end
  end
end
