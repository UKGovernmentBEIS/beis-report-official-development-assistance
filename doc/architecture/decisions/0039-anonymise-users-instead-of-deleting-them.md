# 39. Anonymise users instead of deleting them

Date: 2025-01-24

## Status

Accepted

## Context

The team at DSIT are concerned with GDPR and were debating internally whether
we ought to delete users from the system, especially users who have been
inactive for significant periods of time.

Deleting users - in general - creates data integrity issues, where records
belonging to those users may have to be handled differently if the owning
user is missing; there may also be audit trail issues.

## Decision

Rather than outright deleting users, we have decided to anonymise users in
such a fashion that the user profile is retained - thus preventing any data
integrity issues - whilst removing any personally identifiable information
(PII).

An example follows. Given a user thus:

Username: <first> <last>
Email address: <username@domain>
Telephone: 1234 679810

...when anonymised it would become:

Username: Deleted User <database UUID>
Email address: deleted.user.<database UUID>@<original domain>
Telephone: <blank>

We preserve the original domain name so that we can still identify what
company or organisation the deleted user belonged to, in case that helps
identify any records which that user may be associated with.

We provide two additional mechanisms for anonymisation:

1. An "Anonymise" button in the frontend which allows admin users to self-serve
anonymising inactive users (only applies to users who have previously been
deactivated).

2. A recurring background job which anonymises any users who have been inactive
for five years or more.

## Consequences

The two main benefits to this approach are:

- The team can still see that "a user from the appropriate company made a
change"
- An anonymous user record is stored in the database and can be shown in the
application making implementation more straightforward
- No unnecessary PII is retained

Five years is a long time to wait to find out if the recurring background job
has worked correctly, though we can mitigate the risks around this, of course,
with appropriate tests.
