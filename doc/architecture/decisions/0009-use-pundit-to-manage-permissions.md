# 9. Use Pundit to manage permissions

Date: 2019-11-22

## Status

Accepted

## Context

The service will be used by a variety of different types of users, and we need
to ensure that those users are only able to access the parts of the service that
we want them to.

Our current chosen authentication provider, Auth0, has support for assigning
roles to users, but this couples the service tightly to their service, so we
should avoid this.

## Decision

We will use the 'Pundit' gem to manage users' access to the service. The
permissions will be grouped into roles that can then be assigned to users
requiring a particular level of access.

## Consequences

This will allow us to assign different permissions to different users in a
standardised way, which will improve the overall security of the service.
