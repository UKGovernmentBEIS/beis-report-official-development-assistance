#!/bin/bash
# script to deploy terraform
# exit on error or if a variable is unbound
set -eu

# create a tag from travis variables
# this will be the docker tag that gets deployed
TAG="${TRAVIS_BUILD_NUMBER}-${TRAVIS_COMMIT}"

# set env vars depending on which branch we are on
# TF_VAR_variable_name gets passed to `terraform`
# to set variables.
# The variables starting PROD or STAGING should be exported
# from your running environment

if [ "$TRAVIS_BRANCH" = master ]
then
  echo "creating production env vars for terraform"
  export TF_VAR_docker_image="$TAG"
  export TF_VAR_environment="prod"
  export TF_VAR_secret_key_base="$PROD_SECRET_KEY_BASE"
  export TF_VAR_auth0_client_id="$PROD_AUTH0_CLIENT_ID"
  export TF_VAR_auth0_client_secret="$PROD_AUTH0_CLIENT_SECRET"
  export TF_VAR_auth0_domain="$PROD_AUTH0_DOMAIN"
  export TF_VAR_notify_key="$PROD_NOTIFY_KEY"
  export TF_VAR_notify_welcome_email_template="$PROD_NOTIFY_WELCOME_EMAIL_TEMPLATE"
  export TF_VAR_rollbar_access_token="$ROLLBAR_ACCESS_TOKEN"
  export TF_VAR_domain="$PROD_DOMAIN"
  export TF_VAR_papertrail_destination="$PROD_PAPERTRAIL_DESTINATION"
elif [ "$TRAVIS_BRANCH" = develop ]
then
  echo "creating staging env vars for terraform"
  export TF_VAR_docker_image="$TAG"
  export TF_VAR_environment="staging"
  export TF_VAR_secret_key_base="$STAGING_SECRET_KEY_BASE"
  export TF_VAR_auth0_client_id="$STAGING_AUTH0_CLIENT_ID"
  export TF_VAR_auth0_client_secret="$STAGING_AUTH0_CLIENT_SECRET"
  export TF_VAR_auth0_domain="$STAGING_AUTH0_DOMAIN"
  export TF_VAR_notify_key="$STAGING_NOTIFY_KEY"
  export TF_VAR_notify_welcome_email_template="$STAGING_NOTIFY_WELCOME_EMAIL_TEMPLATE"
  export TF_VAR_rollbar_access_token="$ROLLBAR_ACCESS_TOKEN"
  export TF_VAR_domain="$STAGING_DOMAIN"
  export TF_VAR_papertrail_destination="$STAGING_PAPERTRAIL_DESTINATION"
else
  # we dont want to deploy anywhere else but staging or production
  echo "Not Deploying: we only deploy to staging and production"
  exit 0
fi

echo "deploying $TF_VAR_environment"

cd terraform

# deploy terraform using tfenv
if [ ! -e ~/.tfenv ]
then
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
fi
export PATH="$HOME/.tfenv/bin:$PATH"
tfenv install

/bin/bash install-terraform-provider-for-cf.sh

# CF_PASSWORD, CF_USER, AWS_SECRET_ACCESS_KEY and AWS_ACCESS_KEY_ID
# must be set for the following commands to run

# initialise terraform
terraform init

# select the correct workspace
terraform workspace select $TF_VAR_environment

# apply the terraform
terraform apply -auto-approve

echo "$TF_VAR_environment has been deployed"
