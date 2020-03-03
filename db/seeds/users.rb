administrator = User.find_or_create_by(
  name: "Administrator",
  email: "roda@dxw.com",
  identifier: "auth0|5dc53e4b85758e0e95b062f0",
  role: :administrator
)
delivery_partner = User.find_or_create_by(
  name: "Delivery Partner",
  email: "roda+dp@dxw.com",
  identifier: "auth0|5e5e1ee731555a0cb0ab5a75",
  role: :administrator
)
beis = Organisation.find_by(service_owner: true)
administrator.organisation = beis
administrator.save

other_organisation = Organisation.where(service_owner: false).first
delivery_partner.organisation = other_organisation
delivery_partner.save
