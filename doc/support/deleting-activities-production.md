## Deleting activities

Partner organisation users cannot delete activities via the web app.

Service owner users can only delete certain activities via the web app.

Requests to delete activities should come via Zendesk at the end of reporting
and a complete, approved list of activities to be deleted must be provided.

A rake task is available to help you delete activities and their associations.

Connect to production to run the task, see [console access](./console-access.md)

You will need either the database ID or the RODA identifier of each activity.

Run the task, setting either the database ID as the `ID` environment variable or the RODA identifier as the `RODA_ID` environment variable:

```bash
bin/rails activities:delete RODA_ID=REPLACE-ME
```

or

```bash
bin/rails activities:delete ID=REPLACE-ME
```

Running the rake task will show you which activity the ID is and associated
data, including how many descendants the activity may have, use this
information to verify this is the expected activity.

**If the activity is on the list, we must assume the activity is to be deleted**

However, if any of the activity details is cause for concern for you, it is
absolutely correct to go back and question the requester.

The task will delete ALL associated entities including descendant activities and
their associations.
