administrator = User.find_or_create_by(
  name: "Administrator",
  email: "roda@dxw.com"
)
partner_org_user = User.find_or_create_by(
  name: "Partner Org User",
  email: "roda+dp@dxw.com"
)
beis = Organisation.service_owner
administrator.organisation = beis
administrator.save

other_organisation = Organisation.find_by(role: :partner_organisation)
partner_org_user.organisation = other_organisation
partner_org_user.save
