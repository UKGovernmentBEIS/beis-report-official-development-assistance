# 19. use-data-migrations-to-update-live-data

Date: 2020-04-09

## Status

Accepted

## Context

We need a way to modify existing data on live environments. A good example of this is the new field we made called `geography`. We made is a required field but missed the fact that existing data needed to be migrated based on the value of `recipient_region`. We missed this and needed to take action to correct the mistake on each environment.

We want to avoid having unstructured access to rails consoles on live environments to de-risk the process where possible.

We want to avoid the fact we have to remember to run a manual action before or after a deployment to snure they aren't forgotten.

Using conventional rails migrations as the mechanism for only change data is an option. Though we may wish to change the schema without changing the data migrations. Tieing these 2 responsibilities into the same mechanism seems like it could back us into a corner later.

We would like to document the actions we perform through our code. This would help us understand and debug the state of the service. 

## Decision

Use the data-migrate gem[1] when we need to make changes to data without touching the schema.

Changes to the schema can still include changes relevant to data within the db:migrate. If we were to add the geography feature again, we would add the new column and set the value as a single transaction.

Include the `rake data:migrate` step in the deployment process so it is automatically run after `rake db:migrate`.  

[1] https://github.com/ilyakatz/data-migrate

## Consequences

Changing data on real environments has an automated process.

The team can rollback from data migrations if they need to.

Data migrations and "one-off tasks" are preserved and documented within the code base.

It may be unclear when to use data migrations and when to use db migrations despite including this in the README.


