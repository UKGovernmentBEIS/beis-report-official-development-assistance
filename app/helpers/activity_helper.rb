module ActivityHelper
  def hierarchy_path_for(activity)
    case activity.hierarchy_type
    when "Fund"
      fund = Fund.find activity.hierarchy_id
      organisation_fund_path(activity.hierarchy_id, organisation_id: fund.organisation)
    else
      raise "Other hierarchy types not implemented yet"
    end
  end

  def activity_path_for(activity)
    case activity.hierarchy_type
    when "Fund"
      fund_activity_path(id: activity.id, fund_id: activity.hierarchy_id)
    else
      raise "Other hierarchy types not implemented yet"
    end
  end
end
