# Create the web app.

resource "cloudfoundry_app" "beis-roda-app" {
  name         = "beis-roda-${var.environment}"
  space        = cloudfoundry_space.space.id
  instances    = 2
  disk_quota   = 3072
  timeout      = 120
  docker_image = "thedxw/beis-report-official-development-assistance:${var.docker_image}"
  docker_credentials = {
    username = "${var.docker_username}"
    password = "${var.docker_password}"
  }
  strategy                   = "blue-green-v2"
  health_check_http_endpoint = "/health_check"
  service_binding { service_instance = cloudfoundry_service_instance.beis-roda-redis.id }
  service_binding { service_instance = cloudfoundry_service_instance.beis-roda-postgres.id }
  service_binding { service_instance = cloudfoundry_user_provided_service.papertrail.id }
  environment = {
    "RAILS_LOG_TO_STDOUT"                    = "true"
    "RAILS_SERVE_STATIC_FILES"               = "enabled"
    "RAILS_ENV"                              = "production"
    "SECRET_KEY_BASE"                        = var.secret_key_base
    "DOMAIN"                                 = "https://${var.custom_hostname}.${var.custom_domain}"
    "CANONICAL_HOSTNAME"                     = "${var.custom_hostname}.${var.custom_domain}"
    "ADDITIONAL_HOSTNAMES"                   = var.additional_hostnames
    "AUTH0_CLIENT_ID"                        = var.auth0_client_id
    "AUTH0_CLIENT_SECRET"                    = var.auth0_client_secret
    "AUTH0_DOMAIN"                           = var.auth0_domain
    "NOTIFY_KEY"                             = var.notify_key
    "NOTIFY_WELCOME_EMAIL_TEMPLATE"          = var.notify_welcome_email_template
    "NOTIFY_VIEW_TEMPLATE"                   = var.notify_view_template
    "ROLLBAR_ENV"                            = "paas-${var.environment}"
    "ROLLBAR_ACCESS_TOKEN"                   = var.rollbar_access_token
    "ROLLBAR_DISABLED"                       = var.rollbar_disabled
    "SKYLIGHT_ACCESS_TOKEN"                  = var.skylight_access_token
    "SKYLIGHT_ENV"                           = var.skylight_env
    "SKYLIGHT_ENABLE_SIDEKIQ"                = var.skylight_enable_sidekiq
    "GOOGLE_TAG_MANAGER_CONTAINER_ID"        = var.google_tag_manager_container_id
    "GOOGLE_TAG_MANAGER_ENVIRONMENT_AUTH"    = var.google_tag_manager_environment_auth
    "GOOGLE_TAG_MANAGER_ENVIRONMENT_PREVIEW" = var.google_tag_manager_environment_preview
    "ROBOT_NOINDEX"                          = var.robot_noindex
  }
  # routes need to be declared with the app for blue green deployments to work
  routes {
    route = cloudfoundry_route.beis-roda-route.id
  }
  routes {
    route = cloudfoundry_route.beis-roda-custom-domain-route.id
  }

}
