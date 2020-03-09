# Create a route for the app using the default domain
# and useful hostname based on environment
resource "cloudfoundry_route" "beis-roda-route" {
  domain   = data.cloudfoundry_domain.default.id
  space    = cloudfoundry_space.space.id
  hostname = "beis-roda-${var.environment}"
}
