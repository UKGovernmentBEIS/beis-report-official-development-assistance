# Create a syslog drain pointing at papertrail
# Log destinations in Papertrail should be created for each
# environment. A group should also be created and the log destination
# told to add all systems to that group.
resource "cloudfoundry_user_provided_service" "papertrail" {
  name             = "papertrail-${var.environment}"
  space            = cloudfoundry_space.space.id
  syslog_drain_url = "syslog-tls://${var.papertrail_destination}"
}
