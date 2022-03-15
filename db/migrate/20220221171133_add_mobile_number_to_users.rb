class AddMobileNumberToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :mobile_number, :string
  end
end
