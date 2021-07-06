# 31. Replace PublicActivity with our own hand-rolled way of recording changes

Date: 2021-06-30

## Status

Accepted

## Context

We adopted the `PublicActivity` gem (as documented in [0019](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/731b91f5773c4306f919433af81976d29c5feef1/doc/architecture/decisions/0019-use-public-activity-gem.md)), but the information we record has never been used, or displayed to the user.

Now we're looking at surfacing information about changes to end users it's becoming increasingly clear that is `PublicActivity` is not fit for our needs, and would be easier to build our own approach to logging what changed were made by what user.

## Decision

We have decided to introduce a `HistoricalEvent` model to record changes to models, starting with `Activity`s.

Once we have applied `HistoricalEvents` to all the models we need to track, we can remove all the calls to `PublicActivity` and remove the gem entirely.

## Consequences

This change will allow us to record changes that have been made to various models in a much more granular fashion, allowing us to record what fields have been changed, as well as the associated report, as well as playing those changes back to the user.

When we move away from `PublicActivity` completely, we will have to decide what to do with the old `PublicActivity::Activity` records that have been created - do we delete all the data entirely, or do we use the data to create incomplete `HistoricalActivity` records to give us a complete, if patchy, history.
