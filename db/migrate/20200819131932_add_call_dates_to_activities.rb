class AddCallDatesToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :call_present, :boolean
    add_column :activities, :call_open_date, :date
    add_column :activities, :call_close_date, :date
  end
end
