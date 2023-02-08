class AddExportFilenameToReport < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :export_filename, :string
  end
end
