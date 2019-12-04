# 12. Use Wicked for multi-step forms

Date: 2019-12-04

## Status

Accepted

## Context

The create activity form is large and complex, with arguable too much for a
single page form. Therefore, we need to break this up into more manageable
chunks.

Additionally, the GOV.UK service manual recommends starting with a [one thing per
page](https://www.gov.uk/service-manual/design/form-structure#start-with-one-thing-per-page)
approach.

## Decision

We will use the "Wicked" gem to build a multi-step form for activity.

## Consequences

We can use this gem for other multi-steps forms in the service.

The code for managing a multi-step form is more complex than a single page form,
but the benefit to user experience makes it worth it.
