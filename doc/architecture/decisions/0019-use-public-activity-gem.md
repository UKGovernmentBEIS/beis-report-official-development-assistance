# 19. use-public-activity-gem

Date: 2020-04-09

## Status

Accepted

## Context

Part 7 of the Service Standard on security and privacy[1] includes a section on non-repudiation. The service should be logging what changes were made by each user.

## Decision

We should use the `public_activity` gem to track user actions in the application. This has been proven to provide the right information and context to pass the Service Standard.

## Consequences

User actions will be tracked on creation, update and delete of certain models in the application.

[1] https://www.gov.uk/service-manual/technology/securing-your-information#how-to-assess-information-security
