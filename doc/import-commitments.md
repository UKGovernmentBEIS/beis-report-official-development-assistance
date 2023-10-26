# Import commitments
A commitment is the total funding BEIS commits to at the outset of an activity.

It is one value and cannot be changed.

At this point the application can only import commitments.

## Importing
Commitments are imported by the `commitments:import` rake task.

You will need a csv of valid commitments provided by BEIS:

```csv
RODA identifier,Commitment value
RODA-ID,100000
```

The header fields are case sensitive.

The import script does not accept 'Commitment value' in the form of a string. If the csv has any values provided as strings, the string quotes around the number must be removed before running.

A RODA user email address to be used to log the user who is recorded in the
history log as importing the commitments.

No authorisation is performed, as long as the RODA identifier exists and does
not already have a commitment, the importer will set one.

Copy the csv to production, [see details here](./uploading-and-downloading-files.md)

Run the rake task, setting the two required environment variables:

```bash
bin/rails commitments:import CSV=/path/to/valid.csv USER_EMAIL=known@user.email
```
