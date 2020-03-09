# Create the web app.

resource "cloudfoundry_app" "beis-roda-app" {
  name                       = "beis-roda-${var.environment}"
  space                      = cloudfoundry_space.space.id
  instances                  = 2
  disk_quota                 = 3072
  docker_image               = "thedxw/beis-report-official-development-assistance:${var.docker_image}"
  strategy                   = "blue-green-v2"
  health_check_http_endpoint = "/health_check"
  service_binding { service_instance = cloudfoundry_service_instance.beis-roda-redis.id }
  service_binding { service_instance = cloudfoundry_service_instance.beis-roda-postgres.id }
  service_binding { service_instance = cloudfoundry_user_provided_service.papertrail.id }
  environment = {
    "RAILS_LOG_TO_STDOUT"           = "true"
    "RAILS_SERVE_STATIC_FILES"      = "enabled"
    "RAILS_ENV"                     = "production"
    "SECRET_KEY_BASE"               = var.secret_key_base
    "DOMAIN"                        = var.domain
    "AUTH0_CLIENT_ID"               = var.auth0_client_id
    "AUTH0_CLIENT_SECRET"           = var.auth0_client_secret
    "AUTH0_DOMAIN"                  = var.auth0_domain
    "NOTIFY_KEY"                    = var.notify_key
    "NOTIFY_WELCOME_EMAIL_TEMPLATE" = var.notify_welcome_email_template
    "ROLLBAR_ENV"                   = "paas-${var.environment}"
    "ROLLBAR_ACCESS_TOKEN"          = var.rollbar_access_token
  }
  # routes need to be declared with the app for blue green deployments to work
  routes { route = cloudfoundry_route.beis-roda-route.id }

}
