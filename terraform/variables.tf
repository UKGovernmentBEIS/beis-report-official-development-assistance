variable "environment" {
  type        = string
  description = "the environment the app is running in"
}

variable "papertrail_destination" {
  type        = string
  description = "Where to send logs hostname:port"
}

variable "data_migrate" {
  type        = string
  description = "should data migrations be run automatically on start"
  default     = "true"
}

variable "secret_key_base" {
  type        = string
  description = "secret key base for rails apps"
}

variable "auth0_client_id" {
  type        = string
  description = "AUTH0 Client ID"
}

variable "auth0_client_secret" {
  type        = string
  description = "AUTH0 Client Secret"
}

variable "auth0_domain" {
  type        = string
  description = "AUTH0 domanin"
}

variable "notify_key" {
  type        = string
  description = "Notify key"
}

variable "notify_welcome_email_template" {
  type        = string
  description = "Notify welcome email template"
}

variable "rollbar_access_token" {
  type        = string
  description = "Rollbar access token"
}

variable "skylight_access_token" {
  type        = string
  description = "Skylight access token"
}

variable "skylight_env" {
  type        = string
  description = "Skylight environment name"
}

variable "skylight_enable_sidekiq" {
  type        = string
  description = "Use Skylight to monitor Sidekiq, true/false"
  default     = "false"
}

variable "docker_image" {
  type        = string
  description = "docker image to use"
}

variable "domain" {
  type        = string
  description = "Domain used in email links"
}

variable "google_tag_manager_container_id" {
  type        = string
  description = "Google Tag Manager container identifier"
}

variable "google_tag_manager_environment_auth" {
  type        = string
  description = "Google Tag Manager authentication variable"
}

variable "google_tag_manager_environment_preview" {
  type        = string
  description = "Google Tag Manager preview identifier"
}

variable "rollbar_disabled" {
  type        = string
  description = "Flag to turn off rollbar reporting"
  default     = "false"
}

variable "custom_domain" {
  type        = string
  description = "Name of custom domain created in the cf org"
}

variable "custom_hostname" {
  type        = string
  description = "Custom hostname (prepended to custom_domain for the app and cdn-route)"
}

variable "robot_noindex" {
  type        = string
  description = "should robots be able to index the site?"
  default     = "false"
}
