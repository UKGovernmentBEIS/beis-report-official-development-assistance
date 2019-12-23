module TransactionHelper
  def hierarchy_for(transaction:)
    case transaction.hierarchy_type
    when "Fund" then Fund.find(transaction.hierarchy_id)
    end
  end

  def transaction_hierarchy_path_for(transaction:)
    url_for([transaction.hierarchy.organisation, transaction.hierarchy])
  end

  def hierarchy_object_path(hierarchy:)
    url_for([hierarchy.organisation, hierarchy])
  end
end
