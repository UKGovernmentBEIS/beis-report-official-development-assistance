# 38. Users may belong to multiple organisations

Date: 2024-12-05

## Status

Accepted

## Context

Some RODA users wish to have the ability to view reports, activities, etc from
other organisations. Currently these users have to have their organisation
changed for them so that they can do this, which requires manual intervention
by an administrator.

## Decision

Much of the logic in RODA is predicated on the idea that one user belongs to
one organisation; changing the relationship to one where a user has many
organisations would require a very large engineering effort.

We believe the easiest way to allow a RODA user belonging to one organisation
to be able to view data belonging to other organisations is to maintain its
existing relationship where it belongs to one organisation, but to add an
additional relationship where a user has and belongs to many organisations,
which we are calling "additional organisations". This way, all the existing
logic and tests still work, but we can augment the functionality to allow a
user to switch their current organisation to be a different one from an
"additional organisations" list (the contents of which would be set by an
administrator for a given user).

## Consequences

It will be easier for users who need to see data from other organisations to be
able to do this without requiring manual intervention.

The relationship between a user and its organisation is critical functionality
and so we must tread carefully. Our proposed solution does not require any
changes to the existing policy logic.