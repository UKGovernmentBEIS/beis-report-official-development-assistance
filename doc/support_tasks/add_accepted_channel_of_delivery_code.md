# Add a channel of delivery code to the "accepted" list

From time to time, usually following the assurance of a reporting period, BEIS
will take the view that an additional IATI "channel of delivery" code should be
added to RODA's list of accepted codes. The process for doing this is:

- verify that the candidate code exists in the [list of valid "channel of
  delivery"
  codes](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/master/vendor/data/codelists/IATI/2_03/activity/channel_of_delivery_code.yml)

- add the new "accepted" code to the [list of accepted
  codes](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/master/vendor/data/codelists/BEIS/accepted_channel_of_delivery_codes.yml)

- tweak the `spec/helpers/codelist_helper_spec.rb` to reflect the new quantity
  of accepted codes

- note the detail of the additional code in the `./CHANGELOG.md`

Refer to [commit
6189f90502e20aa9c8200e2b60b8b68e47cf1e40](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/commit/6189f90502e20aa9c8200e2b60b8b68e47cf1e40)
for an example.

- open a PR and get a review and approval

- once the PR is approved contact the requester for their approval to perform a release, if necessary agree a time for the release

- one approved, [release the code to production](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/develop/doc/deployment-process.md)
