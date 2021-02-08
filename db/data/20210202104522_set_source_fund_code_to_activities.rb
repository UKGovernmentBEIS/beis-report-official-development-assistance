class SetSourceFundCodeToActivities < ActiveRecord::Migration[6.0]
  def up
    Activity.fund.where(roda_identifier_fragment: "NF").find_each do |fund|
      set_source_fund_code_on_all_children(fund, Fund::MAPPINGS["NF"])
    end

    Activity.fund.where(roda_identifier_fragment: "GCRF").find_each do |fund|
      set_source_fund_code_on_all_children(fund, Fund::MAPPINGS["GCRF"])
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def set_source_fund_code_on_all_children(fund, source_fund_code)
    fund.update_column(:source_fund_code, source_fund_code)

    fund.child_activities.find_each do |programme|
      programme.update_column(:source_fund_code, source_fund_code)

      programme.child_activities.find_each do |project|
        project.update_column(:source_fund_code, source_fund_code)

        project.child_activities.find_each do |third_party_project|
          third_party_project.update_column(:source_fund_code, source_fund_code)
        end
      end
    end
  end
end
