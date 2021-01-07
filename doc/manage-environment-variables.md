# Manage environment variables

Environment variables are passed to live environments through Terraform by either Travis or a manual deployment.

## Adding a new environment variable

1. Introduce the new variable to Terraform by adding to `terraform/variables.tf`:
   ```
   variable "google_tag_manager_environment_preview" {
     type = string
     description = "Google Tag Manager preview identifier"
   }
   ```
1. Inject the new variables to the app and/or worker (if in doubt add to both):
   ```
   resource "cloudfoundry_app" "beis-roda-app" {
     environment = {
       …
       "GOOGLE_TAG_MANAGER_CONTAINER_ID" = var.google_tag_manager_container_id
       …
   ```
1. Reference the new variable in our `deploy-terraform.sh` script in **2 places**, one for each environment. Changing the prefix to match the environment name that the variable should be applied to:
   ```
   if [ "$TRAVIS_BRANCH" = master ]
     export TF_VAR_google_tag_manager_environment_preview="$PROD_GOOGLE_TAG_MANAGER_ENVIRONMENT_PREVIEW"
   if [ "$TRAVIS_BRANCH" = develop ]
     export TF_VAR_google_tag_manager_environment_preview="$STAGING_GOOGLE_TAG_MANAGER_ENVIRONMENT_PREVIEW"
   ```
1. Add 2 new environment variables to Github matching those names from the previous step. [Github settings can be managed here.](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/settings/secrets/actions)
1. Once all steps are complete and merged, the next time Travis deploys either staging and production those environment variables will be made available to the app
1. Add those variables to our environment file in the RODA 1Password vault as they cannot be read back out of Travis

## Deploying changes to environment variables

There are currently 2 mechanisms available:

1. Automated deployments through Travis
1. Manual deployments made locally where the environment variables are provided from a local `.tfvars` file. See [the Terraform README](/terraform/README.md#Manual-Deployment) for more information.
