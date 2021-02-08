class AddSourceFundCodeToActivity < ActiveRecord::Migration[6.0]
  def change
    add_column :activities, :source_fund_code, :integer
  end
end
