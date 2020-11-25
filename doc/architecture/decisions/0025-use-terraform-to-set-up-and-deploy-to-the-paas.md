# 25. Use Terraform to set up and deploy to the PaaS

Date: 2020-03-03

## Status

Accepted

## Context

We like to control our infrastructure with code. On a previous project we used shell scripts to set up the spaces and services within a PaaS organisation and to also do deploys from Travis.
While shell scripts are fine there is now a useful [terraform provider](https://github.com/cloudfoundry-community/terraform-provider-cf) for cloudfoundry.
The cloudfoundry provider also deploys the app.
Terraform is the default choice for provisioning infrastructure these days.

## Decision

- spaces and services should be created with Terraform
- the application should be deployed with Terraform
- Terraform should be run from Travis to deploy the application

## Consequences

Terraform can destroy an environment as well as create it. We should be able to mitigate this by using CD pipeline to only do the deploys.
