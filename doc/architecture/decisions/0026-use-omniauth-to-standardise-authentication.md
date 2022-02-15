# 26. Use omniauth to standardise authentication

Date: 2020-11-20

## Status

Superceded by [34. Use devise and rotp to manage authentication with sms OTP](0034-use-devise-and-rotp-to-manage-authentication-with-sms-otp.md)

## Context

The application needs a way to authenticate users, we use a third party service
for this (Auth0), see ADR 0006 [1]. As authentication to third party providers is a
well understood problem, it makes sense to leverage an existing gem to handle
this for us.

## Decision

Use the omniauth gem to standardise authentication to third party providers,
this also supports changing provider if deemed necessary.

## Consequences

The omniauth gem has a well known CVE open for it, CVE 2015 9284 [2]. The attack
vector for the exploit is well understood and only applicable under certain
conditions. We mitigate against the risk, following guidance from the gem
author [3].

- we use the omniauth-rails_csrf_protection [4] gem to prevent GET requests to
  the auth routes and add CSRF protection to the POST requests that are used
- all links to the auth routes use POST requests

Having taken these steps, we have ignored the warning for CVE 2015 9284 in our
security warning service that runs againsts this repository [5]

[1]
https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/develop/doc/architecture/decisions/0006-use-auth0-for-authentication.md
[2] https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-9284 
[3] https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284
[4] https://github.com/cookpad/omniauth-rails_csrf_protection
[5] https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/security
