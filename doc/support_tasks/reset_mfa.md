# Reset a user's multi-factor authentication

In the case where a user can't complete MFA because their phone number has
changed, support will need to manually reset the user's MFA settings via the
Auth0 control panel:

- log into Auth0 with an admin account
- switch to the 'roda-production' tenant (or whichever environment is appropriate)
- locate the user via the 'Users' section in 'User Management'
- Reset MFA, eg via the 'Actions' drop-down
- ask the user to log in again and to supply a valid mobile number when prompted

This will allow the user to continue using SMS-based two-factor authentication
for RODA.
