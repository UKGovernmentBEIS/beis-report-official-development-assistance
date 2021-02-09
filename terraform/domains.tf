# Get data for the default domain on the PaaS
data "cloudfoundry_domain" "default" {
  name = "london.cloudapps.digital"
}

# Get data for the custom domain on the PaaS
data "cloudfoundry_domain" "custom" {
  name = "${var.custom_domain}"
}
