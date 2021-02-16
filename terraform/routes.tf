# Create a route for the app using the default domain
# and useful hostname based on environment
resource "cloudfoundry_route" "beis-roda-route" {
  domain   = data.cloudfoundry_domain.default.id
  space    = cloudfoundry_space.space.id
  hostname = "beis-roda-${var.environment}"
}

# Create a route for the app using the default domain
# and useful hostname provided from tfvars (which allows us to easily set www for prod)
resource "cloudfoundry_route" "beis-roda-custom-domain-route" {
  domain   = data.cloudfoundry_domain.custom.id
  space    = cloudfoundry_space.space.id
  hostname = var.custom_hostname
}
