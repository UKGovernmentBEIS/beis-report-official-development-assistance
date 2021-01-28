module BudgetHelper
  def list_of_funding_types
    @list_of_funding_types ||= begin
      Budget.funding_types.to_objects(with_empty_item: false)
    end
  end
end
