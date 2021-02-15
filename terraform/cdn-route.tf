data "cloudfoundry_service" "cdn_route" {
  name = "cdn-route"
}

resource "cloudfoundry_service_instance" "cdn_route" {
  name         = "beis-roda-${var.environment}-cdn-route"
  space        = cloudfoundry_space.space.id
  service_plan = data.cloudfoundry_service.cdn_route.service_plans["cdn-route"]
  json_params  = <<EOF
{"domain": "${var.custom_hostname}.${var.custom_domain}"}
EOF
}

