# 14. use-coveralls-for-monitoring--test-coverage

Date: 2019-12-20

## Status

Accepted

## Context

We have started to miss test coverage for a few methods. We noticed this problem where we had delivered a feature with a feature test but had forgotten to add enough unit coverage. When the feature test later changed coverage was lost.

We want to keep our test coverage as high as possible without having to run manual checks as these take time.

## Decision

Use the free tier of Coveralls to give us statistics and to give our pull requests feedback. 

## Consequences

- The free tier only works on public repositories.
- Pull request feedback should help us spot patches in coverage and continously improve it
- The later we add this gem the harder it will be to achieve a high coverage
