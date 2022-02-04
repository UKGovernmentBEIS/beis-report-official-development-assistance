# 34. Use devise and rotp to manage authentication with SMS OTP

Date: 2022-01-25

## Status

Accepted

Supercedes [6. Use Auth0 for authentication](0006-use-auth0-for-authentication.md)
Supercedes [26. Use omniauth to standardise authentication](0026-use-omniauth-to-standardise-authentication.md)

## Context

We previously used Auth0, via omniauth, to manage users and sessions. We have a user requirement to require MultiFactor authentication using one-time passwords sent over SMS. Auth0 are planning on moving this feature to only be included in expensive enterprise plans.

## Decision

We will create our own [devise](https://github.com/heartcombo/devise) [strategy](https://github.com/heartcombo/devise/tree/main/lib/devise/strategies) that uses [rotp](https://github.com/mdp/rotp) to generate one-time passwords that are sent over SMS via [GOV.UK Notify](https://www.notifications.service.gov.uk/).

## Considerations made

We tested the assumption that SMS OTP was a requirement, and it is
We decided that the Auth0 costs of an enterprise were too high for our needs
We explored competitors to Auth0, but as we are not ever planning on supporting SSO, we decided that running an external service, even if bought, is an unnecessary overhead
We considered writing our own authentication system in Rails from scratch, but decided that devise gives us enough out of the box to warrant its use
We considered using [devise-two-factor](https://github.com/tinfoil/devise-two-factor), but it would require enough bending to ignore app-based MFA and to add SMS OTP process flow that it makes sense for us to write our own strategy
We considered retaining omniauth as a middleware to enable us to easily use other providers, but we do not believe we will need to do this in the future
