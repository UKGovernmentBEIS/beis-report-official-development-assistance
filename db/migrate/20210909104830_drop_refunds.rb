class DropRefunds < ActiveRecord::Migration[6.1]
  def up
    Refund.table_name = "refunds"
    begin
      Refund.connection
      raise "We expected the Refunds table to be empty" unless Refund.count.zero?

      drop_table :refunds
    rescue ActiveRecord::StatementInvalid => e
      puts "Refunds already deleted: #{e}"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
