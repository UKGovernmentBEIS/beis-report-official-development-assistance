administrator = User.find_or_initialize_by(
  name: "Administrator",
  email: "roda@dxw.com"
)
delivery_partner = User.find_or_initialize_by(
  name: "Delivery Partner",
  email: "roda+dp@dxw.com"
)

administrator.password = "LlEeTtMmEeIiNn!1"
delivery_partner.password = "LlEeTtMmEeIiNn!1"

beis = Organisation.service_owner
administrator.organisation = beis
administrator.save!

other_organisation = Organisation.find_by(role: :delivery_partner)
delivery_partner.organisation = other_organisation
delivery_partner.save!
