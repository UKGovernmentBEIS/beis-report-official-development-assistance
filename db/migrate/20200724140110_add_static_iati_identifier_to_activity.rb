class AddStaticIatiIdentifierToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :transparency_identifier, :string
  end
end
