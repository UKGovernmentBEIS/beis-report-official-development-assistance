class RemoveLegacyOtpColumns < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :encrypted_otp_secret
    remove_column :users, :encrypted_otp_secret_iv
    remove_column :users, :encrypted_otp_secret_salt
  end
end
