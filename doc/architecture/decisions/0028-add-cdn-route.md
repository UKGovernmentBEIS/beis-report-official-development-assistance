# 28. Add CDN route

Date: 2021-02-10

## Status

Accepted

## Context

The apps need to be hosted on a custom domain, behind CloudFront

## Decision

We will create a cdn-route on GPaas, which will create a CloudFront endpoint with the custom domain
This will also generate the TLS certificates

## Consequences

We may need to configure the cdn-route to forward particular headers or cookies, if they are configured to not be forwarded to the application
