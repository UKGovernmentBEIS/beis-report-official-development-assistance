# 11. Use GOV.UK Design System Form Builder

Date: 2019-12-02

## Status

Accepted

## Context

Building forms in Rails that are compliant with the GOVUK Design System involve
manually declaring the correct HTML structure, class names and ARIA attributes,
which is time-consuming and hard to get right.

Additionally, our validation errors currently use Rails' default pattern, rather
than the one recommended for use as part of the design system, which is designed
with accessibility in mind.

## Decision

We will use DfE's `govuk_design_system_formbuilder` to simplify the creation of
GOV.UK Design System-compliant forms.

As we are currently using Simple Form rather than Rails' default form builder
for our other forms, the two form builders can co-exist for the time being,
whilst we transition the forms over.

## Consequences

- Forms will be more compliant with the GOV.UK Design System and accessibility
  standards and easier to work with
- We will however need to spend some time moving the existing forms over to
  new form builder
- Uses standard Rails' i18n keys for form labels, whereas our existing forms do
  not, so these would need to be moved over
