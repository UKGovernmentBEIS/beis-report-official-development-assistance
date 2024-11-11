# Glossary of terms

## Activity

Generic term for any project undertaken by an organisation with DSIT money. Top level things such as funds are also activities in the code. See also fund, programme, project, third-party project. `Activity` in the code, with distinction by the `level` attribute.

## Actual spend

Also: actuals

Money spent for an activity. For historical reasons, some actuals have negative values, but newer actuals should only ever have positive values.

Subclass of `Transaction`

## Adjustments

Corrections made to fix inconsistencies with reported actuals.

Subclass of `Transaction`

## BEIS

Acronym for the DEPARTMENT FOR BUSINESS, ENERGY & INDUSTRIAL STRATEGY, under which RODA was developed. In 2023, the department was reorganised and renamed DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY (DSIT). There are still many places in RODA where the old name persists, such as email copy and database columns.

## Budget

Money allocated for an activity.

RODA currently recognises two types of budgets: direct and external.

## Codelists

Originally designating the specific codes (and their metadata) used by IATI. These are public, they have official versions, and must be used when preparing data to be reported to IATI. Stored in the `vendor` folder.

Extended to include DSIT-specific codes and metadata, also stored in the `vendor` folder. We prefer to record any such codes in a YAML file rather than in constants.

## DSIT

Acronym for the DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY, created in 2023 out of the old BEIS.

## Extending organisation

Terminology originating from IATI. According to IATI, this is "an organisation that manages the budget and direction of an activity on behalf of the funding organisation".

RODA uses this as a permission checker: users belonging to the `extending_organisation` have permission to create and modify projects (level C activities) that their organisation "extends"; permission to create child activities of programmes (level B activities) that their organisation extends.

## Financial quarter (and financial year)

A financial year 200n starts on 1 April 200n and ends on 31 March 200(n+1). It is divided in four quarters, numbered 1 to 4, each encompassing 3 calendar months.

E.g. the time period 1 Jan 2021 - 31 Mar 2021 is the 4th financial quarter of the financial year 2020.

In the app, we label them `FQ[1-4] 202n-202(n+1)`, e.g. `FQ4 2020-2021`. The financial year on its own is labelled `FY 202n`.

## Financials

A generic term for money associated with an activity: budgeted money, money that is forecast to be spent, and money that is actually spent.

NB: DSIT RODA is a reporting tool, not an accounting system. It is not responsible for error checking.

## Forecast spend

Also: planned disbursement, forecasts, forecasted spend

Money anticipated to be spent for an activity during a financial quarter.

## Fund

Also "level A"

A source of financing for development assistance projects.

A fund is recorded as an activity entity, but there is also a `Fund` class that is not database-persisted.

`Fund` instances have an `activity` method for getting the activity entity, but they also draw in basic information from a `fund_types` codelist (ID, name and short name). `Fund` provides class and instance methods used in various contexts such as views, when exporting/downloading data, and when needing to get the source fund of an activity (of any level).

## Implementing organisation

An organisation that physically carries out an activity or intervention. [Further information](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/pull/1544)

## Level

The only way of organising activities in a hierarchy that all the organisations seem to agree upon is to regard them as a four tier system, with the fund at the top as level A, and three "child" levels, B, C, and D.

## Outgoing Transfer

A way to record money that is being moved from one activity to another.

## PO

Partner organisation (formerly Delivery partner)

An organisation that collaborates with DSIT to deliver aid to one or more countries or regions.

## Programme

Also "level B"

An activity (a way of organising money, organisations, and people involved) recording how DSIT money is allocated and spent by a specific partner organisation. DSIT is the organisation that manages programmes.

## Project

Also "level C"

An activity managed by a PO, recording how money is received and spent from DSIT on a specific activity (such an aid programme, a public health campaign etc). The PO is responsible for correctly reporting all the financial details, target areas, etc.

## Refunds

Represent money returned, that will be deducted when calculating net spends. Always stored as negative values.

Subclass of `Transaction`

## Report

A record of the financials relating to an organisation's activities during a specific financial quarter. Forecasts are what the organisation thinks, at the time of reporting, that they will spend during each forecast financial quarter that is pertinent to that report.

Actuals are what money the organisation spent during the financial quarter relevant to the report.

## SID

Statistics on International Development

"This publication provides statistics about the amount of Official Development Assistance (ODA) the UK provided in [year], including UK ODA as a percentage of Gross National Income (GNI) (the ODA:GNI ratio) and various other breakdowns of ODA spend."

## Third-party project

Also "level D"

An activity that is done on behalf of a PO by a third party, such as an university. It's the partner organisation that manages this activity and reports on the financials to DSIT, i.e. `third_party_project.extending_organisation = partner_organisation`
