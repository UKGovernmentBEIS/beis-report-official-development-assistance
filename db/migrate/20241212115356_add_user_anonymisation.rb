class AddUserAnonymisation < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :deactivated_at, :datetime
    add_column :users, :anonymised_at, :datetime

    User.where(active: false).each do |user|
      user.update_column(:deactivated_at, user.updated_at)
    end

    remove_column :users, :active
  end

  def down
    add_column :users, :active, :boolean, default: true

    User.where.not(deactivated_at: nil).each do |user|
      user.update_column(:active, false)
    end

    remove_column :users, :deactivated_at, :datetime
    remove_column :users, :anonymised_at, :datetime
  end
end
