class AddUkDpNamedContactToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :uk_dp_named_contact, :string
  end
end
