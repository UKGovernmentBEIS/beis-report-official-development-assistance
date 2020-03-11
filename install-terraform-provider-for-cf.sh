#!/bin/bash
# script to install the Terraform plugin for CloudFoundry
# https://github.com/cloudfoundry-community/terraform-provider-cf/wiki#manually
set -e

# install the cloudfoundry provider if it isnt already
if [ ! -e ~/.terraform.d/plugins/linux_amd64/terraform-provider-cloudfoundry ]
then
  echo "installing Cloudfoundry Terraform plugin"

  mkdir -p ~/.terraform.d/plugins/linux_amd64
  curl -L https://github.com/cloudfoundry-community/terraform-provider-cf/releases/download/v0.11.0/terraform-provider-cloudfoundry_linux_amd64 \
    -o ~/.terraform.d/plugins/linux_amd64/terraform-provider-cloudfoundry
  chmod u+x  ~/.terraform.d/plugins/linux_amd64/terraform-provider-cloudfoundry


  echo "finished downloading Cloudfoundry Terraform plugin"
fi
