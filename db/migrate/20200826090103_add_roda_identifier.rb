class AddRodaIdentifier < ActiveRecord::Migration[6.0]
  def change
    change_table :activities do |t|
      t.string :roda_identifier_fragment
      t.string :roda_identifier_compound

      t.index [:roda_identifier_compound]
    end
  end
end
