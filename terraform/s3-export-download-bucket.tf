data "cloudfoundry_service" "aws-s3-bucket" {
  name = "aws-s3-bucket"
}

resource "cloudfoundry_service_instance" "beis-roda-s3-export-download-bucket" {
  name         = "beis-roda-${var.environment}-s3-export-download-bucket"
  space        = cloudfoundry_space.space.id
  service_plan = data.cloudfoundry_service.aws-s3-bucket.service_plans["default"]
}

resource "cloudfoundry_service_instance" "beis-roda-s3-export-download-bucket-private" {
  name         = "beis-roda-${var.environment}-s3-export-download-bucket-private"
  space        = cloudfoundry_space.space.id
  service_plan = data.cloudfoundry_service.aws-s3-bucket.service_plans["default"]
}
