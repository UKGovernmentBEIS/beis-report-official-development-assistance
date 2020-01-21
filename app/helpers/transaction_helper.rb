module TransactionHelper
  def create_transaction_path_for(hierarchy:)
    case hierarchy.class.name
    when "Fund"
      fund_transactions_path(hierarchy)
    when "Programme"
      programme_transactions_path(hierarchy)
    end
  end
end
