Users cannot delete activities via the web app.

Requests to delete activities usually come in via Zendesk support tickets.

Sometimes we'll be given the database ID of the activity to delete:
```
activity = Activity.find(id)
```

Most often we'll be given its RODA identifier:
```
activity = Activity.by_roda_identifier("REPLACE-ME")
```

Check whether the activity has any associated entities that would be deleted along with it:

```
activity.children.count
Budget.where(parent_activity_id: activity.id).count
Transaction.where(parent_activity_id: activity.id).count
PlannedDisbursement.where(parent_activity_id: activity.id).count

Comment.where(activity_id: activity.id).count
ImplementingOrganisation.where(activity_id: activity.id).count
```

If any of these are present, and we haven't been explicitly told to delete the activity and all its associated entities, stop and confirm with the requester that this is what they want.

Other associations have database constraints in place to prevent deletion of associated activities, such as transfers:
```
Transfer.where(source_id: activity.id).count
Transfer.where(destination_id: activity.id).count
```

If there are such associations present, confirm the course of action with the requester.
