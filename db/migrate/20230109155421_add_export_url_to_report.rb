class AddExportUrlToReport < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :export_url, :string
  end
end
