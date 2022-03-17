class AddMobileNumberConfirmedAt < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :mobile_number_confirmed_at, :datetime
  end
end
