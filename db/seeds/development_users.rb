administrator = User.find_or_initialize_by(
  name: "Administrator",
  email: "roda@dxw.com",
  identifier: "auth0|5dc53e4b85758e0e95b062f0"
)
delivery_partner = User.find_or_initialize_by(
  name: "Delivery Partner",
  email: "roda+dp@dxw.com",
  identifier: "auth0|5e5e1ee731555a0cb0ab5a75"
)

administrator.password = "LlEeTtMmEeIiNn!1"
delivery_partner.password = "LlEeTtMmEeIiNn!1"

beis = Organisation.service_owner
administrator.organisation = beis
administrator.save!

other_organisation = Organisation.find_by(role: :delivery_partner)
delivery_partner.organisation = other_organisation
delivery_partner.save!
