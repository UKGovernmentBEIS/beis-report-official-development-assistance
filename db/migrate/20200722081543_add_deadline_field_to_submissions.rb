class AddDeadlineFieldToSubmissions < ActiveRecord::Migration[6.0]
  def up
    add_column :submissions, :deadline, :date
  end

  def down
    remove_column :submissions, :deadline, :date
  end
end
