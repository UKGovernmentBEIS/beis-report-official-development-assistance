# Change Log

## Unreleased changes

- Add Google Tag Manager in place of templated Google Analytics code
- Ensure missing I18n strings cause tests to fail
- Users can be created/updated both locally and in Auth0
- Users can be associated with multiple organisations
- Allow roles to be assigned to users
- Users are welcomed and able to create their new password to access the service
- Service name updated from "Overseas" to "Official"
- Users can create and view Funds; users can create and view Activities
- Users can download an XML representation of an Activity
- Split activity form into multiple steps
- Create Transactions associated with a Fund
- Remove the distinction between Fund and Activity from the user
- Users can edit an organisation
- Users can edit the basic fund record
- Users can edit a transaction
- Users can edit an activity record
- Transactions record the provider and receiver organisations
- All forms now use `govuk_design_system_formbuilder` instead of `simple_form`
- Activity multi-step form now has validations
- Users can view an XML representation of Transactions and Funds
- Delivery partners cannot interact with organisations they are not already associated with
- Users can only create funds if they are associated with a given organisation
