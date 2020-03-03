# Get data for the default domain on the PaaS
data "cloudfoundry_domain" "default" {
  name = "london.cloudapps.digital"
}
