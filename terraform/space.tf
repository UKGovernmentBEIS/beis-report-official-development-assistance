# This creates a space but does not add any users to it.
# Until you add your user to the space via the UI with space manager
# and space developer permissions the rest of the terraform will fail
resource "cloudfoundry_space" "space" {
  name = var.environment
  org  = data.cloudfoundry_org.beis-report-official-development-assistance.id
}
