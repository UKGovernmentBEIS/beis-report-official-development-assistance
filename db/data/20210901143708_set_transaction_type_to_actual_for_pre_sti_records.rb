# Run me with `rails runner db/data/20210901143708_set_transaction_type_to_actual_for_pre_sti_records.rb`

Transaction.where(type: nil).update_all(type: "Actual")
