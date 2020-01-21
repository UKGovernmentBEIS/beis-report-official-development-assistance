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
  organisation_params = FactoryBot.build(
    :organisation, name: "Department for Business, Energy & Industrial Strategy"
  ).attributes
  organisation = Organisation.find_or_create_by(organisation_params)

  user = User.find_or_initialize_by(
    name: "Generic development user",
    email: "roda@dxw.com",
    identifier: "auth0|5dc53e4b85758e0e95b062f0",
    role: :administrator
  )
  user.organisation = organisation
  user.save

  fund_params = FactoryBot.build(:fund, name: "GCRF", organisation: organisation).attributes
  Fund.find_or_create_by(fund_params)
end
