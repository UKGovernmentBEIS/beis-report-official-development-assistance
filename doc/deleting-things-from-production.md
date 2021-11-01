## Deleting activities
Users cannot delete activities via the web app.

Requests to delete activities should come via Zendesk at the end of reporting
and a complete, approved list of activities to be deleted must be provided.

A rake task is available to help you delete activities and their associations.

Connect to production to run the task, see [console access](./console-access.md)

You will need the database ID of each activity, often we'll be given the activity's 
RODA identifier, so you first need to locate the database ID on the Rails console:

```ruby
activity = Activity.by_roda_identifier("REPLACE-ME").pluck(:id)
```

Then run the task, setting the activity database ID as the ID environment
variable:

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
