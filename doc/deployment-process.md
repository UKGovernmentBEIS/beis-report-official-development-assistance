# Deployment process

## Production

As outlined in the [dxw development workflow guide](http://playbook.dxw.com/#/guides/development-workflow?id=deploying), production deploys are done by manually merging develop into master. To give us a slightly more formal process around what gets deployed and when and also to give us visibility into the things that have been deployed, we additionally follow these steps when releasing to production:

Releases are documented in the [CHANGELOG](CHANGELOG.md) following the [Keep a changelog](https://keepachangelog.com/en/1.0.0/) format.

When a new release is deployed to production, a new second-level heading should be created in CHANGELOG.md with the release number and details of what has changed in this release.

The heading should link to a Github URL at the bottom of the file, which shows the differences between the current release and the previous one. For example:

### Example

```
## [release-1]
- A change
- Another change

[release-1]: https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/compare/release-1...release-0
```

### Steps

1. Create a release branch and make a pull request
   - Create a branch from develop for the release called release-X where X is the release number
   - Update CHANGELOG.md to:
     document the changes in this release in a bullet point form
     add a link to the diff at the bottom of the file
   - Document the changes in the commit message as well
   - Push the changes up to Github `git push -u origin release-x`
   - Create a pull request to merge that release into **develop** with content from the CHANGELOG.md
   - Get that pull request reviewed and approved
1. Review and merge the release pull request
   The pull request should be reviewed to confirm that the changes in the release are safe to ship and that CHANGELOG.md accurately reflects the changes included in the release.
1. Update your local develop branch and tag the merge commit on develop `git tag release-X [merge-commit-for-release]`
1. Push the tag to Github `git push origin refs/tags/release-X` (we need the
   refs otherwise git will not know if you mean the tag or the branch as they
   have the same name)
1. Confirm the release candidate and perform any prerequisites
   - Confirm the release with any relevant people (product owner, delivery manager, etc)
   - Think about any dependencies that also need considering: dependent parts of the service that also need updating; environment variables that need changing/adding; third-party services that need to be set up/updated; data migrations to be run
1. Announce the release
   Let the team know about the release. This is posted in Slack under #beis-roda. Typical form is:

   ```
   @here :badgerbadgerbadger: Release N of RODA going to production :badgerbadgerbadger:
   ```

1. Manually merge to master to release
   Once the release pull request has been merged into the develop branch, the production deploy can be performed by manually merging develop into master:
   ```
   git fetch
   git checkout master
   git pull
   git merge origin/develop
   # Edit the commit message to reference the release number
   # e.g. "Release 43" or "merge origin/develop for release 43"
   git push
   ```
1. Production smoke test
   Once the code has been deployed to production, carry out a quick smoke test to confirm that the changes have been successfully deployed.
1. [Run any data migrations](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance#data--one-off-tasks) that are meant to be run as part of the release
1. Move all the Trello cards from "Awaiting deployment" to "Done"

## Staging

1. Open a pull request back into the `develop` branches with your changes
1. Get that pull request code reviewed and approved
1. Check that any prerequisite changes to things like environment variables or third-party service configuration is ready
1. Merge the pull request

The changes should be automatically applied by Github Actions. [You can track the progress of Github Actions jobs at this link](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/actions?query=workflow%3ADeploy).

## Migrations

These should be automatically run when new containers are started during a deployment. This instruction is included in the app/docker-entrypoint.sh.
