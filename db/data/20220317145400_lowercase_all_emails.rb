ActiveRecord::Base.connection.execute(
  "UPDATE users SET email = LOWER(email)"
)
