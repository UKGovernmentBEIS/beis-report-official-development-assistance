user = User.find_or_create_by(
  name: "Generic development user",
  email: "roda@dxw.com",
  identifier: "auth0|5dc53e4b85758e0e95b062f0",
  role: :administrator
)
beis = Organisation.find_by(service_owner: true)
user.organisation = beis
user.save
