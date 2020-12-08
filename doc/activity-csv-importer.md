# Activity CSV Importer

We need to import legacy data for delivery partners, so they don't have to
manually re-key it into RODA.

## Implementing Organisations

These are currently stored on a one-to-many association between `Activity` and `ImplementingOrganisation`.

### Handling multiple implementing organisations

Whilst there can be more than one implementing organisation stored against an
activity, this is quite rare. Additionally, the CSV can only reference one
implementing organisation per activity.

Therefore, the decision was made that in the case when the CSV references an
activity that already exists with more than one implementing organisation,
running the import will result in *one* being updated with the new information
and the remaining implementing organisations being removed.

We note that an alternative solution would need to be found once the end-user
can run this process. This seems fine for now whilst the importer can only be
run by a developer in the console.
