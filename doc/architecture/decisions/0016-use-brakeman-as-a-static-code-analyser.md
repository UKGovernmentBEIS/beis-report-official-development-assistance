# 16. Use Brakeman as a static code analyser

Date: 2020-02-28

## Status

Accepted

## Context

We need to be confident that our application is secure and remains so during development and the life time of the service.

## Decision

Install the Brakeman gem as a static code analyser to help us identify security issues.

Add an additional check to CI that will check we still have no warnings on every new pull request that is tested (Pull requests must pass before they can be merged given out GitHub configuration).

## Consequences

We will be notified before we introduce security risks into a live environment.

Brakeman requires frequent updating with new issues so we will need to trust in Dependabot to help keep our version up to date.

Brakeman could give us false confidence that we are secure. Brakeman cannot check for every type of attack so we must rely on penetration tests as well to have confidence that we are as secure as we can be.
