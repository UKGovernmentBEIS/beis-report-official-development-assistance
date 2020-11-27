class AddFundPillarToActivities < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :fund_pillar, :integer
  end
end
