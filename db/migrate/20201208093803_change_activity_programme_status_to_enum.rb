class ChangeActivityProgrammeStatusToEnum < ActiveRecord::Migration[6.0]
  def up
    add_column :activities, :programme_status_integer, :integer

    Activity.find_each do |activity|
      programme_status = Integer(activity.programme_status_before_type_cast, exception: false)
      programme_status = 8 if activity.programme_status_before_type_cast == "08"
      programme_status = 9 if activity.programme_status_before_type_cast == "09"
      activity.update_column(:programme_status_integer, programme_status)
    end

    remove_column :activities, :programme_status, :string
    rename_column :activities, :programme_status_integer, :programme_status
  end

  def down
    add_column :activities, :programme_status_string, :string

    Activity.find_each do |activity|
      next if activity.programme_status.nil?

      programme_status = "%02d" % activity.programme_status_before_type_cast
      activity.update_column(:programme_status_string, programme_status)
    end

    remove_column :activities, :programme_status, :string
    rename_column :activities, :programme_status_string, :programme_status
  end
end
