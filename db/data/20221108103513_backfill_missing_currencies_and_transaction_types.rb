# Run me with `rails runner db/data/20221108103513_backfill_missing_currencies_and_transaction_types.rb`

# Transactions (actuals, refunds and adjustments) were being created with blank attributes:
# - currency
# - transaction_type
#
# This isn't causing an immediate problem, but they are "transactions" and so
# ought to conform to te normal transaction behaviour.

# This is adapted from db/data/20211004_backfill_missing_attrs_on_refunds_and_adjustments.rb

finder = Transaction.where(currency: nil, transaction_type: nil)

puts "Setting currency and transaction_type on #{finder.count} transactions..."

finder.each do |transaction|
  transaction.update_columns(
    transaction_type: Transaction::TRANSACTION_TYPE_DISBURSEMENT,
    currency: "GBP"
  )
end

puts "-> there are now #{finder.reload.count} transactions where currency and transaction_type are nil"

finder = Transaction.where(currency: nil)

puts "Setting currency on #{finder.count} transactions..."

finder.each do |transaction|
  transaction.update_columns(currency: "GBP")
end

puts "-> there are now #{finder.reload.count} transactions where currency is nil"
