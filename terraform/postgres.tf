# Get data about the postgres service on the PaaS
# so we can get the guid of the service plan we want to use.
data "cloudfoundry_service" "postgres" {
  name = "postgres"
}

# Create a postgres database named with the environment.
# Enable the pgcrypto and plpgsql extensions.
# Increase the timeouts since the default of 15 minutes is too
# short for postgres db creation

resource "cloudfoundry_service_instance" "beis-roda-postgres" {
  name         = "beis-roda-${var.environment}-postgres"
  space        = cloudfoundry_space.space.id
  service_plan = data.cloudfoundry_service.postgres.service_plans["small-ha-13"]
  json_params  = "{\"enable_extensions\": [\"pgcrypto\",\"plpgsql\"]}"
  timeouts {
    create = "2h"
    delete = "2h"
    update = "2h"
  }
  replace_on_params_change       = false
  replace_on_service_plan_change = false
}
