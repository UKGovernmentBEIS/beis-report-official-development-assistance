# Email notifications
The application sends various notifications by email, this document outlines how
this works from a technical standpoint.

## Account emails
Most emails that relate to user accounts are sent by Auth0.

All others are sent by the applicaiton via GOV.UK Notify.

## Mail Notify Gem
We use this gem to interact with the GOV.UK Notify service.

[https://github.com/dxw/mail-notify](https://github.com/dxw/mail-notify)

## GOV.UK notify service
[https://www.notifications.service.gov.uk/services/15322373-3ee0-4c9c-aef7-be3e967f2f3e](https://www.notifications.service.gov.uk/services/15322373-3ee0-4c9c-aef7-be3e967f2f3e)

BEIS owned so access can be granted by them.

You will need the API key in the NOTIFY_KEY environment variable. The key for
each environment can be found here https://www.notifications.service.gov.uk/services/15322373-3ee0-4c9c-aef7-be3e967f2f3e/api/keys

## Templates
We use two templates to send email notifications:

- Welcome email
- View email

See the templates at https://www.notifications.service.gov.uk/services/15322373-3ee0-4c9c-aef7-be3e967f2f3e/templates

The templates ids are supplied as environment variables:

- NOTIFY_WELCOME_EMAIL_TEMPLATE
- NOTIFY_VIEW_TEMPLATE

Confirm the Template ID in GOV.UK Notify and ensure you have the environment
variables set.

### Welcome email
The welcome email is sent to new users and takes a series of variables, changes
to the content are made in the Notify service.

### View email
The Mail Notify gem allows us to assemble the entire body of the email in our
code which gives us greater flexibility of the content, see
[https://github.com/dxw/mail-notify#with-a-view](https://github.com/dxw/mail-notify#with-a-view)

All email notifications other than the welcome email are sent using this
template.


## Previews
Once setup, you can preview emails in your development environment:

http://localhost:3000/rails/mailers/report_mailer

## Sidekiq
We use a Redis backed Sidekiq worker to actually send the emails to notify.
