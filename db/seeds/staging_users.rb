administrator = User.find_or_create_by(
  name: "Administrator",
  email: "roda@dxw.com"
)
delivery_partner = User.find_or_create_by(
  name: "Delivery Partner",
  email: "roda+dp@dxw.com"
)
beis = Organisation.service_owner
administrator.organisation = beis
administrator.save

other_organisation = Organisation.find_by(role: :delivery_partner)
delivery_partner.organisation = other_organisation
delivery_partner.save
