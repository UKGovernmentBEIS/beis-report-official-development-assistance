class AddGeographyData < ActiveRecord::Migration[6.0]
  def up
    activities_with_only_regions = Activity.where(recipient_country: nil).where.not(recipient_region: nil)
    activities_with_only_regions.update_all(geography: :recipient_region)
  end

  def down
    activities_with_only_regions = Activity.where(recipient_country: nil).where.not(recipient_region: nil)
    activities_with_only_regions.update_all(geography: nil)
  end
end
