class RenameUkDpNamedContactToUkPoNamedContact < ActiveRecord::Migration[6.1]
  def change
    rename_column :activities, :uk_dp_named_contact, :uk_po_named_contact
  end
end
