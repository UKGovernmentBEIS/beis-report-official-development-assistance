class AddSectorCategoryToActivities < ActiveRecord::Migration[6.0]
  include CodelistHelper

  def up
    sectors = sector_radio_options
    activities_with_sectors = Activity.where.not(sector: [nil, ""])

    activities_with_sectors.each do |activity|
      sector = sectors.find { |sector| sector.code == activity.sector }
      activity.update(sector_category: sector.category)
    end
  end

  def down
    Activity.update_all(sector_category: nil)
  end
end
