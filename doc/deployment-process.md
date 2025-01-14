# Deployment

## Introduction

Deployments are made from AWS via CodePipelines.

To view deployments or trigger them, you will need access to the hosting, see
the [hosting documentation](/doc/hosting.md) for more information.

**IMPORTANT**: The CodePipelines are polling-based. If a pipeline has not run in over
30 days, AWS will turn it off, and a developer will have to [trigger a
release](#monitor-or-trigger-deployments) manually.

**NOTE**: There is no indication in Github what branch is deployed where or any
deployment status, the only way to find out is via the CodePipelines in AWS.

## Environments

Whilst we have four environments, they are linked together in pairs, which
limits their value:

Merges into the `develop` branch will deploy the changes to:

- development
- staging

Merging into the `main` branch will deploy the changes to:

- training
- production


## Monitor or trigger deployments

### Monitoring

To monitor deployments follow these steps:

- sign in to AWS with your `digital-paas-production-account` account
- assume the role for the appropriate environment, see [hosting
  documentation](/doc/hosting.md#assuming-roles)
- Locate _CodePipelines_ in the services menu
- Click on the name of the Pipeline

You will see the three stages of deployment: Source, Build and Deploy. You can
view details of each stage.

### Triggering

To trigger a deployment:

- sign in to AWS with your `digital-paas-production-account` account
- assume the role for the appropriate environment, see [hosting
  documentation](/doc/hosting.md#assuming-roles)
- Locate _CodePipelines_ in the services menu
- Click on the name of the Pipeline
- Click on the _Release changes_ button, top right

The branch will be deployed, see [environments](#environments)

## Release process

Production deploys are done by manually merging develop into main. To give us a
slightly more formal process around what gets deployed and when and also to give
us visibility into the things that have been deployed, we additionally follow
these steps when releasing to production:

Releases are documented in the [CHANGELOG](/CHANGELOG.md) following the [Keep
a changelog](https://keepachangelog.com/en/1.0.0/) format.

When a new release is deployed to production, a new second-level heading should
be created in CHANGELOG.md with the release number and details of what has
changed in this release.

The heading should link to a Github URL at the bottom of the file, which shows
the differences between the current release and the previous one. For example:

```
## Release-1 - 2024-01-01

[Full changelog][1]

- A change
- Another change

[unreleased]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-1...HEAD
[1]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-0...release-1
```

### Steps 

1. Confirm the release candidate and perform any prerequisites
   - Confirm the release with any relevant people (product owner, delivery
     manager, etc)
   - Think about any dependencies that also need considering: dependent parts of
     the service that also need updating; environment variables that need
     changing/adding; third-party services that need to be set up/updated; data
     migrations to be run
1. Create a release branch and make a pull request
   - Create a branch from develop for the release called release-X where X is
     the release number
   - Update CHANGELOG.md to:
     - document the changes in this release in a bullet point form
     - add a link to the diff at the bottom of the file
   - Copy the list of changes from the changelog into the commit message
   - Push the changes up to Github 
        ```
        git push -u origin release-X # e.g. git
        push -u origin release-120 
        ```
   - Create a pull request to merge that release into _develop_ with content
     from the CHANGELOG.md
1. Get that pull request reviewed and merged
   - Confirm that the changes in the release are safe to ship and that
     CHANGELOG.md accurately reflects the changes included in the release.
   - Merge the pull request
1. Update your local develop branch and tag the merge commit on develop 
        ``` 
        git tag release-X [merge-commit-for-release]
        ```
1. Push the tag to Github (we need the refs otherwise git will not know if you
mean the tag or the branch as they have the same name)   
        ``` 
        git push --tags
        ```
1. Create a Github release
    - Click on Releases
    - Click on Draft new release
    - Choose the release tag
    - Set the release title to 'Release x'
    - Set the body of the release to list of changes for the release, copy them
      from the CHANGELOG.md
    - Click on Publish release
1. Manually merge develop into main in order to release
   - Once the release pull request has been merged into the develop branch, the
     production deploy can be performed by manually merging develop into main:
        ```
        git fetch 
        git checkout main 
        git pull 
        git merge origin/develop
        ```
    - Set the merge commit title to 'Release x'
    - `git push origin main`
1. Production smoke test once the code has been deployed to production, carry
out a quick smoke test to confirm that the changes have been successfully
deployed.
1. Announce the release Let the team know about the release. This is posted in
Slack under #beis-roda, link to the release notes.
