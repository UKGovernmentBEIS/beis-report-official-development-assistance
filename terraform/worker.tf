resource "cloudfoundry_app" "beis-roda-worker" {
  name              = "beis-roda-${var.environment}-worker"
  space             = cloudfoundry_space.space.id
  instances         = 1
  strategy          = "blue-green-v2"
  command           = "bundle exec sidekiq"
  health_check_type = "none"
  memory            = 1024
  disk_quota        = 3072
  timeout           = 300
  docker_image      = "thedxw/beis-report-official-development-assistance:${var.docker_image}"
  docker_credentials = {
    username = "${var.docker_username}"
    password = "${var.docker_password}"
  }
  service_binding { service_instance = cloudfoundry_service_instance.beis-roda-redis.id }
  service_binding { service_instance = cloudfoundry_service_instance.beis-roda-postgres.id }
  service_binding { service_instance = cloudfoundry_user_provided_service.papertrail.id }
  environment = {
    "RAILS_LOG_TO_STDOUT"           = "true"
    "RAILS_SERVE_STATIC_FILES"      = "enabled"
    "RAILS_ENV"                     = "production"
    "SECRET_KEY_BASE"               = var.secret_key_base
    "DOMAIN"                        = "https://${var.custom_hostname}.${var.custom_domain}"
    "AUTH0_CLIENT_ID"               = var.auth0_client_id
    "AUTH0_CLIENT_SECRET"           = var.auth0_client_secret
    "AUTH0_DOMAIN"                  = var.auth0_domain
    "NOTIFY_KEY"                    = var.notify_key
    "NOTIFY_WELCOME_EMAIL_TEMPLATE" = var.notify_welcome_email_template
    "NOTIFY_VIEW_TEMPLATE"          = var.notify_view_template
    "ROLLBAR_ENV"                   = "paas-${var.environment}"
    "ROLLBAR_ACCESS_TOKEN"          = var.rollbar_access_token
    "ROLLBAR_DISABLED"              = var.rollbar_disabled
  }
}
