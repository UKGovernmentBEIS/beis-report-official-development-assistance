class ChangeGcrfStrategicAreaArraysToIntegers < ActiveRecord::Migration[6.0]
  def up
    rename_column :activities, :gcrf_strategic_area, :gcrf_strategic_area_string
    add_column :activities, :gcrf_strategic_area, :integer, array: true, default: []

    Activity.where.not(gcrf_strategic_area_string: nil).all.each do |activity|
      activity.gcrf_strategic_area = activity.gcrf_strategic_area_string.map(&:to_i)
    end

    remove_column :activities, :gcrf_strategic_area_string
  end

  def down
    rename_column :activities, :gcrf_strategic_area, :gcrf_strategic_area_integer
    add_column :activities, :gcrf_strategic_area, :string, array: true

    Activity.where.not(gcrf_strategic_area_integer: []).all.each do |activity|
      activity.gcrf_strategic_area = activity.gcrf_strategic_area_string.map(&:to_s)
    end

    remove_column :activities, :gcrf_strategic_area_integer
  end
end
