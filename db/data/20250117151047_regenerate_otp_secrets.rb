# Run me with `rails runner db/data/20250117151047_regenerate_otp_secrets.rb`

# On migrating from devise-two-factor 4.x to 5.x, we need to regenerate all our OTP secrets.
# 4.x used three columns, encrypted_otp_secret, encrypted_otp_secret_iv, and encrypted_otp_secret_salt.
# 5.x uses a single JSON-containing VARCHAR containing multiple values, for example:
# {"p":"yrnrIYTCt+/YGEg2F8QCfieMHJ02zjEi","h":{"iv":"fmmU6Jx5f+XEg9u0","at":"LozZUSLUGwo6US0sW39Vmw==","e":"QVNDSUktOEJJVA=="}}
#
# Once `otp_secret` has been populated, we can do a Phase 2 release to remove the old encrypted_otp_secret,
# encrypted_otp_secret_iv, and encrypted_otp_secret_salt columns.
User.transaction do
  User.find_each do |user|
    user.update!(otp_secret: User.generate_otp_secret)
  end
end
