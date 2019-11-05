# 6. Use Auth0 for authentication

Date: 2019-10-28

## Status

Accepted

## Context

We need to allow a number of users to sign in to the service in order to use it.
In order to implement this quickly, we'll use Auth0 to manage this.

As Auth0's authentication uses OAuth2, it should be straightforward to migrate
to another service, if BEIS have a preference for something else.

## Decision

We will use the free tier of Auth0 for the private beta.

## Consequences

We will need to consider the extent of our integration with Auth0 as an interim
solution for which a permanent replacement is being sought.
