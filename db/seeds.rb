# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Generic development user
if Rails.env.development?
  User.find_or_create_by(
    name: "Generic development user",
    email: "roda@dxw.com",
    identifier: "auth0|5dc53e4b85758e0e95b062f0"
  )
end
