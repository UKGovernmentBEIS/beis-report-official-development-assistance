# 36. Use Audited for Budget Revisions

Date: 2023-03-15

## Status

Accepted

## Context

Budgets can go through a number of revisions; they can be updated over time as
more or less funding comes in, or the scope of the activity changes.

We want to be able to keep a history of these revisions. They will be displayed
on a new revisions page and exported as "current" and "original" budgets.

### Audited

The [Audited gem](https://github.com/collectiveidea/audited) provides us with
an easy way to achieve the desired functionality, with minimal changes to the
existing Budget model.

Audited has "audits", which contain information about changes to a model, and
"revisions" which represent the audited model at the time the audit was
created.

The features of Audited include:
- the ability to keep an audit history, including limiting what is considered
  a change
- the ability to optionally attach a comment to an audit
- the ability to keep track of which user made the changes

## Decision

We will use the Audited gem to keep track of budget revisions. A new audit will
be created when a budget is created, or when the value attribute of a budget is
updated.

## Consequences

- Adding budget revision functionality is significantly simplified.
- We must run a data migration in order to create audits for any existing
  budgets. The audit created for each budget will be considered "original" which
  is inaccurate for a small minority of budgets that have been updated.
- The data migration must be run out-of-hours before any users have a chance to
  create or update any budgets. Whilst the migration is somewhat robust, it will
  not handle instances where an audited budget has been created before the
  migration is run.
- The difference in language between Audited and the application may lead to
  confusion for future developers. The Audited gem uses "revision" to refer to
  any version of a record, including the original version. The application
  uses "revision" to refer only to a budget that has been updated. I.e., budget
  revision 1 in the application will correspond with Audited revision 2.
