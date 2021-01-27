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
1. Inject the new variable to the app and/or worker (if in doubt add to both) by
   adding it in `terraform/app.tf`:
   ```
   resource "cloudfoundry_app" "beis-roda-app" {
     environment = {
       …
       "GOOGLE_TAG_MANAGER_CONTAINER_ID" = var.google_tag_manager_container_id
       …
   ```
1. Add the new variable to the deploy settings for staging and production in
   `.github/workflows/deploy.yml`, check the correct step for each env:
  ```
  TF_VAR_google_tag_manager_container_id: ${{ secrets.STAGING_GOOGLE_TAG_MANAGER_CONTAINER_ID }}
  ```

1. Add 2 new environment variables to GitHub secrets - one for staging, one for prod. [GitHub settings can be managed here.](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/settings/secrets/actions) prepending the environment name as appropriate, `STAGING_` for staging and `PROD_` for production.
  ```
  STAGING_GOOGLE_TAG_MANAGER_CONTAINER_ID=...
  PROD_GOOGLE_TAG_MANAGER_CONTAINER_ID=...
  ```
1. Once all steps are complete and merged, the next time GitHub Actions deploys either staging and production those environment variables will be made available to the app
1. Add those variables to our environment files and tfvars files in the RODA 1Password vault as they cannot be read back out of GitHub Secrets

## Deploying changes to environment variables

There are currently 2 mechanisms available:

1. Automated deployments through GitHub Actions
1. Manual deployments made locally where the environment variables are provided from a local `.tfvars` file. See [the Terraform README](/terraform/README.md#Manual-Deployment) for more information.
