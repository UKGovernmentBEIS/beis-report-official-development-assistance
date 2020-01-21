module HierarchyHelper
  def hierarchy_path_for(item:)
    # TODO there must be a better way
    # organisation_fund_path when hierarchy is a fund
    # fund_programme_path when hierarchy is a programme
    case item.hierarchy.class.name
    when "Fund"
      url_for([item.hierarchy.organisation, item.hierarchy])
    when "Programme"
      url_for([item.hierarchy.fund, item.hierarchy])
    end
  end

  def edit_hierarchy_path_for(item:)
    # TODO there must be a better way
    case item.hierarchy.class.name
    when "Fund"
      url_for([:edit, item.hierarchy.organisation, item.hierarchy])
    when "Programme"
      url_for([:edit, item.hierarchy.fund, item.hierarchy])
    end
  end
end
