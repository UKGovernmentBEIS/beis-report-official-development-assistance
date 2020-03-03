variable "environment" {
  type        = string
  description = "the environment the app is running in"
}

variable "papertrail_destination" {
  type        = string
  description = "Where to send logs hostname:port"
}
