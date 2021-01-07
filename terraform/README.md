# Terraform Deployment

We use terraform to create the spaces and services needed by the application and to deploy the application itself.

We use terraform workspaces to keep the terraform state seperate for each environment.

We store our state in an s3 bucket on the PaaS in the terraform space.

Deploys will happen automatically from Github Actions

## Manual Deployment

We should avoid manual deployments but the following instructions will allow you to do one.

### Setup

- go to the application `/terraform` directory
- install [tfenv](https://github.com/tfutils/tfenv)
- install Terraform version `0.12.x` using `tfenv`, use `tfenv list-remote` to see available versions. Our Terrafiles are not backwards-compatible with Terraform `0.11.x`
- install the latest [cloundfoundry provider](https://github.com/cloudfoundry-community/terraform-provider-cf/wiki#installations)

### Deployment

- checkout the correct branch
  - `develop` for staging or other testing environments
  - `master` for production
- export environment variables for AWS credentials
  These can be found in the RODA 1password vault
  Your local `~/.aws/credentials` should include the values for `aws_access_key` and `aws_secret_access_key`
- export environment variables for PaaS credentials
  `export CF_USER=<your paas email>`
  `export CF_PASSWORD=<your paas password>`
- build and push a new docker image if needed
  `cf app` can tell you what image is currently being used
  [DockerHub has a list of existing docker images you can use](https://hub.docker.com/repository/docker/thedxw/beis-report-official-development-assistance/tags?page=1), eg. `1508-ffa43b1944e37d4bd583e1a083a74779abc7a9a7`
- export environment variables of the form TF_VAR_variablename to match the variables in [variables.tf](variables.tf)
  e.g. TF_VAR_environment for the environment variable
  or create a tfvars file eg `terraform/staging.tfvars` with the following:
  ```
  environment = "[TF SPACE]"
  data_migrate= "true"
  auth0_client_id= "[REDACTED]"
  auth0_client_secret= "[REDACTED]"
  auth0_domain= "[REDACTED]"
  domain= "https://beis-roda-[TF SPACE].london.cloudapps.digital"
  notify_key= "[REDACTED]"
  notify_welcome_email_template= "[REDACTED]"
  rollbar_access_token= "[REDACTED]"
  secret_key_base= "[REDACTED]"
  skylight_access_token= "[REDACTED]"
  skylight_env= "[REDACTED]"
  papertrail_destination= "logs2.papertrailapp.com:[REDACTED]"
  docker_image= "1486-9932ccf922b37f544430af4584443736cf50eb5b"
  ```
- `terraform init`
- switch workspace to the right environment
  `terraform workspace select $TF_VAR_environment`
  You can view available workspaces with `terraform workspace list`
- `terraform plan` to check it will do what you think it will
  if using a tfvars file you will need to provide it with `-var-file`
- `terraform apply` to deploy
  if using a tfvars file you will need to provide it with `-var-file`
- If changes are not applied you can run `cf restage <app>`
