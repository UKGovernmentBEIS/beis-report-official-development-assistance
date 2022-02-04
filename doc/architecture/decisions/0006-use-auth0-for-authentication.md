# 6. Use Auth0 for authentication

Date: 2019-10-28

## Status

Superceded by [16. Disable Auth0's requirement for Javascript during the authentication journey](0016-disable-auth0-s-requirement-for-javascript-during-the-authentication-journey.md)

Superceded by [34. Use devise and rotp to manage authentication with sms OTP](0034-use-devise-and-rotp-to-manage-authentication-with-sms-otp.md)

## Context

We need to allow a number of users to sign in to the service in order to use it.
In order to implement this quickly, we'll use Auth0 to manage this.

As Auth0's authentication uses OAuth2, it should be straightforward to migrate
to another service, if BEIS have a preference for something else.

Auth0 provides views for authentication that we can use in our user journeys.
There are two versions of these views 'Classic' and 'New'.

Classic uses JavaScript and is not progressively enhanced. New uses language
that results in a poor user experience.

## Decision

We will use the free tier and 'Classic' views of Auth0 for the private beta.

## Consequences

The Classic login uses JavaScript that is not progressively enhanced, however
the speed using it brings the team is a higher priority than the work to
replace it for the moment.

We will need to consider the extent of our integration with Auth0 as an interim
solution for which a permanent replacement is being sought.
