# Terraform Deployment

We use terraform to create the spaces and services needed by the application and to deploy the application itself.

We use terraform workspaces to keep the terraform state seperate for each environment.

We store our state in an s3 bucket on the PaaS in the terraform space.

Deploys will happen automatically from travis

## Manual Deployment

We should avoid manual deployments but the following instructions will allow you to do one.

### Setup
- install terraform (use `tfenv`)
- install the latest [cloundfoundry provider](https://github.com/cloudfoundry-community/terraform-provider-cf/wiki#installations)

### Deployment
- use the correct branch
  - develop for staging
  - master for production
- export environment variables for AWS credentials
  These can be found in the RODA 1password vault
- export environment variables for PaaS credentials
- build and push a new docker image if needed
  `cf app` can tell you what image is currently being used
- export environment variables of the form TF_VAR_variablename to match the variables in [variables.tf](variables.tf)
  e.g. TF_VAR_environment for the environment variable
  or create a tfvars file
- `terraform init`
- switch workspace to the right environment
  `terraform workspace select $TF_VAR_environment`
- `terraform plan` to check it will do what you think it will
   if using a tfvars file you will need to provide it with `-var-file`
- `terraform apply` to deploy
   if using a tfvars file you will need to provide it with `-var-file`
