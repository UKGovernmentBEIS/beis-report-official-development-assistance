# Import commitments
A commitment is the total funding BEIS commits to at the outset of an activity.

It is one value and cannot be changed.

At this point the application can only import commitments.

## Importing
Commitments are imported by the `commitments:import` rake task.

You will need a csv of valid commitments provided by BEIS:

```csv
RODA identifier,Commitment value,Financial quarter,Financial year
RODA-ID,100000,1,2021
```

The header fields are case sensitive.

A RODA user email address to be used to log the user who is recorded in the
history log as importing the commitments.

No authorisation is performed, as long as the RODA identifier exists and does
not already have a commitment, the importer will set one.

Copy the csv to production, [see details here](./importing-new-delivery-partner-data.md#import-activity-data-in-production)

Run the rake task, setting the two required environment variables:

```bash
bin/rails commitments:import CSV=/path/to/valid.csv USER_EMAIL=known@user.email
```
