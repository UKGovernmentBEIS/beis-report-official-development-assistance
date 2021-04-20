# Console access

We need console access to bootstrap the service with users and organisations. We may need a way to access live environments for debugging or incident management purposes in future.

If we do need to open a rails console on production we should pair through the commands we execute to mitigate the risk of data loss.

## Prerequisites

You must have an account that has been invited to the Government Platform as a Service (GPaaS) account. Developers from the product team should be able to invite you, failing that Sean C. and Morgan D. from BEIS are organisation administrators.

You must have have been given 'Space developer' access to the intended space, for example "prod".

[You can sign in to check your account and permissions here](https://admin.london.cloud.service.gov.uk).

## Access

1. From a local terminal login to Cloud Foundry and select the intended space
    ```
    $ cf login
    ```
2. Connect to the environment (in this case production)
    ```
    $ cf ssh beis-roda-prod
    ```
3. Run the intended commands
    ```
    $ bin/rails c
    ```

    or

    ```
    $ bin/rails db:seed
    ```
