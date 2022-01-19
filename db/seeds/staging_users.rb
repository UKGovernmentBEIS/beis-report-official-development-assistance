administrator = User.find_or_create_by(
  name: "Administrator",
  email: "roda@dxw.com",
  identifier: "auth0|5dc54a826560de0e885bb41b"
)
delivery_partner = User.find_or_create_by(
  name: "Delivery Partner",
  email: "roda+dp@dxw.com",
  identifier: "auth0|5e554c1b37de640d5dd3ea61"
)
beis = Organisation.service_owner
administrator.organisation = beis
administrator.save

other_organisation = Organisation.find_by(role: :delivery_partner)
delivery_partner.organisation = other_organisation
delivery_partner.save
