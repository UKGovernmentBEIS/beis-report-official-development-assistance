variable "environment" {
  type        = string
  description = "the environment the app is running in"
}

variable "papertrail_destination" {
  type        = string
  description = "Where to send logs hostname:port"
}

variable "secret_key_base" {
  type        = string
  description = "secret key base for rails apps"
}

variable "notify_key" {
  type        = string
  description = "Notify key"
}

variable "notify_welcome_email_template" {
  type        = string
  description = "Notify welcome email template"
}

variable "notify_view_template" {
  type        = string
  description = "Notify generic view template"
}

variable "notify_otp_verification_template" {
  type        = string
  description = "Notify OTP SMS template"
}

variable "rollbar_access_token" {
  type        = string
  description = "Rollbar access token"
}

variable "docker_image" {
  type        = string
  description = "docker image to use"
}

variable "docker_username" {
  type        = string
  description = "docker username"
}

variable "docker_password" {
  type        = string
  description = "docker password"
}

variable "additional_hostnames" {
  type        = string
  description = "Additional hostnames for the application to be allowed to use (comma separated)"
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
