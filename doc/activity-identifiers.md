# Types of identifiers

RODA maintains four different types of identifier for activities. They differ
according to where the identifier comes from, what it's used for, and what rules
it has to conform to. The identifiers are named:

- Previous Identifier
- Partner Organisation Identifier
- RODA Identifier
- Transparency Identifier

## Previous Identifier

For activities that come from ingest of historical data from IATI, this is the
identifier contained in the ingested data. It is stored verbatim; RODA does not
modify the ingested value before storing it.

If an activity has a Previous Identifier stored, then that will be used to
identify the activity when re-exporting information about it to IATI.

## Partner Organisation Identifier

This is the identifier by which a Partner Organisation refers to the activity in
their own records. It has no syntactic restrictions; it can contain any
characters the user wants and RODA does not assume anything about its structure
or about the other systems that use this identifier.

The Partner Organisation Identifier should not be used for anything within RODA
other than displaying it so that a Partner Organisation can cross-reference with
their own records. It should not be exported to third-party organisations.

It can be explicitly added to an activity via the service, and it may be edited
at any time.

This identifier is also populated by the ingest process -- RODA makes a best
guess as to what the Partner Organisation Identifier for an ingested activity is,
based on the Previous Identifier. It removes the strings `GB-GOV-13-`, `GCRF-`,
and `NEWT-` from the start of the Previous Identifier, and stores the result as
the Partner Organisation Identifier.

## RODA Identifier

Starting with activities reported in Q2 2021-2022, the previous RODA identifier
scheme was replaced with a new one. Activities prior to this retain their
existing RODA identifier, but any new activities will have a new, auto generated
one assigned.

The RODA identifier still reflects the hierarchy of activities, with each level
adding to the parent identifier. For this reason, new activities added to older
parents will have a hybrid identifier.

The main motivation for this change was to remove both BEIS and
partner organisations from the creation of the identifiers, which was a heavy burden and
slowed the reporting process drastically, users no longer have to enter any
information into the service in order to create a new activity and its
identifier.

The RODA identifier retains the constraints of the legacy version.

For each new activity in the hierarchy we create a unique, seven character
string for each new activity, from the following characters:

`23456789ABCDEFGHJKLMNPQRSTUVWXYZ`

The RODA identifier also includes the fund code (level A activity code), this is
achieved by adding these two values to the identifier for top level activities
(level B).

## RODA Identifier (legacy version <= Q1 2021-2022)

The identifier by which RODA knows an activity, and should be regarded as the
canonical identifier for an activity. It is used to identify the activity in
exported data. It must be globally unique; no two activities within RODA, at any
level, may have the same RODA Identifier.

Because of restrictions imposed by organisations we export data to, the RODA
Identifier has a maximum length of 40 characters and may only contain letters
(`A` to `Z` in upper or lower case), digits (`0` to `9`), and the characters
`-`, `_`, `/` and `\`.

The RODA Identifier is strictly hierarchical; the Identifier for an activity is
a prefix for all the activities sitting under it. For example, if a level A
activity has the Identifier `GCRF`, then all level B activities sitting under it
will have identifiers beginning `GCRF-`.

Within the service, users enter only the _component_ of the identifier for the
level, and RODA combines them automatically. For example, when entering the RODA
Identifier for a level B activity under the level A activity `GCRF`, if the user
enters `UKSA` then the combined RODA Identifier for the level B activity becomes
`GCRF-UKSA`.

The full schema for a RODA Identifier at level D is `A-B-CD`, where `A` is the
component from level A, `B` the component from level B, and so on. BEIS will set
the identifiers at levels A and B, and the `A-B` portion must be at most 18
characters long. Partners Organisations will set the identifiers at levels C and D,
and the `CD` portion must be at most 21 characters long.

Because these identifiers are used to identify activities in exported data, they
must remain stable, so they cannot be edited after first being set. Because of
the length validation, an activity can only have a RODA Identifier added after
its parent has been given one.

RODA Identifiers are not assigned by the ingest process, they are only set by
end users.

## Transparency Identifier

This identifier is a transformed version of the RODA Identifier that's
compatible with the IATI rules. Any string of characters in the RODA Identifier
that are not letters, digits, or `-` are replaced with `-`, and the
organisational prefix `GB-GOV-13-` is prepended to the result.

This identifier is not set by the ingest process _or_ assigned directly by end
users; it is derived from the RODA Identifier when that is set.

The Transparency Identifier is used to identify activities in data exported to
IATI, if the activity does not have a Previous Identifier stored.
