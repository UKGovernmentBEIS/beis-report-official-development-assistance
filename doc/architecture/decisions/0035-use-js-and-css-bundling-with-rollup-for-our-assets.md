# 35. Use JS and CSS bundling with Rollup for our assets

Date: 2023-01-05

## Status

Accepted

## Context

We previously used Webpacker to handle all of our assets (JS, CSS etc), but Webpacker has now been deprecated in favour of the `jsbundling-rails` gem or Rails' "Import maps". As Webpacker is on life support, the maintainers are not upgrading any client-side dependencies, meaning vulnerabilities may be uncovered in Webpacker's dependencies and making it difficult to upgrade those in our own codebase. As an organisation, we've decided to go down the jsbundling (and cssbundling) route to bundle our assets on other projects.

## Decision

We'll use jsbundling and cssbundling to handle our assets on RODA. We'll use Rollup as our JS module bundler.

## Consequences

Moving away from Webpacker should make it easier to upgrade to Rails 7 when we decide to do that, as jsbundling and cssbundling is supported for Rails 7. We should now have more control over our own clientside dependencies, which will make them easier to upgrade.
