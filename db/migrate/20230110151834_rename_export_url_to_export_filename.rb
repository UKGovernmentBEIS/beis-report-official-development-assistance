class RenameExportUrlToExportFilename < ActiveRecord::Migration[6.1]
  def change
    rename_column :reports, :export_url, :export_filename
  end
end
