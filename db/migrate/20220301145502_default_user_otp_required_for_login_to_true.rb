class DefaultUserOtpRequiredForLoginToTrue < ActiveRecord::Migration[6.1]
  def up
    change_column :users, :otp_required_for_login, :boolean, default: true
    sql = <<~SQL
      UPDATE users SET otp_required_for_login = 't'
    SQL

    ActiveRecord::Base.connection.execute sql
  end

  def down
    change_column :users, :otp_required_for_login, :boolean
  end
end
