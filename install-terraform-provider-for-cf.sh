#!/bin/bash
# script to install the Terraform plugin for CloudFoundry
# https://github.com/cloudfoundry-community/terraform-provider-cf/wiki#manually
set -e

# install the cloudfoundry provider if it isnt already
if [ ! -e ~/.terraform.d/plugins/linux_amd64/terraform-provider-cloudfoundry ]
then
  echo "installing Cloudfoundry Terraform plugin"

  echo "1"
  mkdir -p ~/.terraform.d/plugins/linux_amd64
  echo "2"
  chmod +x ~/.terraform.d/plugins/linux_amd64
  echo "3"
  curl -O https://github.com/cloudfoundry-community/terraform-provider-cf/releases/download/v0.11.0/terraform-provider-cloudfoundry_linux_amd64 \
    -o ~/.terraform.d/plugins/linux_amd64/terraform-provider-cloudfoundry
  echo "4"
  chmod +x ~/.terraform.d/plugins/linux_amd64
  echo "5"


  echo "finished downloading Cloudfoundry Terraform plugin"
fi
