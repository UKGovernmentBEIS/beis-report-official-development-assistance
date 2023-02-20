# Run me with `rails runner db/data/20230220095332_set_transaction_date_on_commitments.rb`

commitments_to_update = Commitment.where(transaction_date: nil)

puts "Setting transaction date on #{commitments_to_update.count} Commitments"

commitments_to_update.each do |commitment|
  print "."
  commitment.update(transaction_date: commitment.first_day_of_financial_period)
end

commitments_to_update.reload

puts "\nThere are now #{commitments_to_update.count} commitments with no transaction date"
