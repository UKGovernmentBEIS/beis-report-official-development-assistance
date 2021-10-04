# Run me with `rails runner db/data/20211004_backfill_missing_attrs_on_refunds_and_adjustments.rb`

# Refunds and Adjustments were being created with blank attributes:
# - currency
# - transaction_type
#
# This isn't causing an immediate problem, but they are "transactions" and so
# ought to conform to te normal transaction behaviour.

finder = Transaction.where(currency: nil, transaction_type: nil)

puts "Fixing up #{finder.count} transactions..."

finder.each do |transaction|
  transaction.update_columns(
    transaction_type: Transaction::TRANSACTION_TYPE_DISBURSEMENT,
    currency: "GBP"
  )
end

puts "-> there are now #{finder.reload.count} transactions still to fix"
