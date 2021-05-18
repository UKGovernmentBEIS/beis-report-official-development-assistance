administrator = User.find_or_create_by(
  name: "Administrator",
  email: "roda@dxw.com",
  identifier: "auth0|5dc54a826560de0e885bb41b",
  role: :administrator
)
delivery_partner = User.find_or_create_by(
  name: "Delivery Partner",
  email: "roda+dp@dxw.com",
  identifier: "auth0|5e554c1b37de640d5dd3ea61",
  role: :administrator
)
beis = Organisation.service_owner
administrator.organisation = beis
administrator.save

other_organisation = Organisation.where(service_owner: false).first
delivery_partner.organisation = other_organisation
delivery_partner.save
