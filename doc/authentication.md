Authentication

The applications facilitates user management, authentication and
authorisation itself.

## Two factor authentication

We rely on the following gems for our implementation of two factor
authentication:

- [Devise](https://github.com/heartcombo/devise)
- [Devise-Two-Factor
  Authentication](https://github.com/devise-two-factor/devise-two-factor)

As there are a number of Devise 2FA gems, make sure you are referencing the
correct documentation!

Our one time passwords are time based. Generally speaking OTP have a concept of
'drift' to allow for differences in the time on both the service and client.

Whilst many 2FA Devise gems have separate setting for the expiry and drift,
Devise-Two-Factor does not appear to, combining them into a single
`[otp_allowed_drift](https://github.com/devise-two-factor/devise-two-factor#enabling-two-factor-authentication)` that we have set to 5 minutes in
`[config/initializers/devise.rb](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/develop/config/initializers/devise.rb)`.

Something appears to introduce an additional 30 seconds on top of this which is
documented in our
`[spec/features/users_can_sign_in_spec.rb](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/develop/spec/features/users_can_sign_in_spec.rb)`,
at this point we can only assume this is part of the underlying
[rotp](https://github.com/mdp/rotp) gem that is used.
