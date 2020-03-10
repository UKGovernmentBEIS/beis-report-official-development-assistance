# Get data about the redis service on the PaaS
# so we can get the guid of the service plan we want to use.
data "cloudfoundry_service" "redis" {
  name = "redis"
}

# Create a redis instance named with the environment.
# Increase the timeouts since the default of 15 minutes is too
# short for redis instance creation
# The service plan name is actually 'tiny-ha-3.2' when listed
# by `cf marketplace -s redis` however the '.' is converted to a '_'
# when used by terraform

resource "cloudfoundry_service_instance" "beis-roda-redis" {
  name         = "beis-roda-${var.environment}-redis"
  space        = cloudfoundry_space.space.id
  service_plan = data.cloudfoundry_service.redis.service_plans["tiny-ha-4_x"]
  timeouts {
    create = "2h"
    delete = "2h"
    update = "2h"
  }
}
