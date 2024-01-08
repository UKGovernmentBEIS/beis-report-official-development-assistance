class CreateDownloadsTable < ActiveRecord::Migration[6.1]
  def change
    create_table :downloads, id: :uuid do |t|
      t.string :purpose
      t.string :filename
      t.timestamps
    end
  end
end
