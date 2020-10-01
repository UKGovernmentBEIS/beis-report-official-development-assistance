# 23. use-docker-hub-in-deployments

Date: 2020-10-01

## Status

Accepted

## Context

Our CI/CD pipeline uses containers (Docker) as does our hosting platform (GOVUK
PaaS), we need a way to store built images from our pipeline so our hosting
platform can access and deploy them.

Docker hub is one solution offered by the maker of Docker itself.

## Decision

Use [Docker hub](https://hub.docker.com/) to store built deployment container
images to facilitate continuous delivery.

Host the built container images on the dxw Docker hub account.

## Consequences

Built container images will be stored on the dxw Docker hub account. This splits
the ownership of the dependencies the service is built on between BEIS and dxw.
This can be rectified later by BEIS having their own Docker hub account.

Pushing our deployment images to Docker hub makes them open, however as
the service source is already open, we take steps to ensure all secrets are
injected at runtime, there should be no leakage via a image that could
not be gained from the source itself.
