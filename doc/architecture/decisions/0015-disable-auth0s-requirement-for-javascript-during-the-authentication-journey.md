# 16. Disable Auth0's requirement for Javascript during the authentication journey

Date: 2020-02-05

## Status

Accepted

Partial supersede of [6. Use Auth0 for authentication](0006-use-auth0-for-authentication.md)

## Context

The welcome and the sign in journey currently bounce our user to pages controlled by Auth0. Auth0 give us 2 options called 'experiences' in the admin area under 'Universal Login':

1. Classic - requires Javascript to be enabled in the browser
2. New - no Javascript required

https://auth0.com/docs/universal-login/new

The [service standard does not mention failing or passing an assessment if the service doesn't work without JS](https://www.gov.uk/service-manual/service-assessments/pre-july-2019-digital-service-standard) the guidance I can find is from the [service manual which advises that we should use progressive enhancement](https://www.gov.uk/service-manual/technology/using-progressive-enhancement) to ensure that when a user doesn't have JS enabled, the service remains functional.

## Decision

Use Auth0 in all environments without requiring Javascript.

## Consequences

- When users follow the welcome journey they will be met with an extra step that states "Go back to all applications" which is not obviously clear. We plan to test how this affects the user journey before deciding what action to take. The hypothesis is that whilst it isn't clear, users should be able to succeed if they click the button. Auth0 does not give us the ability to configure the text on this page, or to remove this page when using our custom welcome emails. A big change we could make would be to stop using GOV.UK Notify for our welcome emails and instead pay for and customise the Auth0 email templates, using their email providers.
