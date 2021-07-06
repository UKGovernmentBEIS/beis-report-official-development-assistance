# Forecasts and versioning

_Forecasts_, also called _planned disbursements_ in an IATI context,
represent plans or predictions about money that will be spent in the future. A
forecast relates to an _activity_ and to a _financial quarter_ (represented by
the `parent_activity_id`, `financial_year` and `financial_quarter` attributes),
and has a _value_. So a forecast represents facts of the form:

> We plan to spend £50,000 on solar panel research in Q3 2022.

Forecasts are part of the financial data that is captured in quarterly _reports_
for all activities in levels C and D. A report functions as a _snapshot_ of the
state of the financial data at a point in time, and once a report is approved,
its content should remain immutable. So if we change our mind about how much
we're going to spend...

> We plan to spend £64,000 on solar panel research in Q3 2022.

... we need to be able to store this without modifying records associated with
any approved or other non-editable reports.

Therefore forecast information is _versioned_. Normally in Rails, a database
record, represented by an instance of an ActiveRecord model class, corresponds
to a single real-world entity in the problem domain. For forecasts, the
`forecasts` table should be thought of more as a low-level
implementation of a higher-level data structure, and as such the
`Forecast` model should not be used directly. This document explains
how to work with forecast data, and how the underlying storage implementation
works.


## Working with forecasts

The `Forecast` class should not be accessed directly. In general,
querying this class will return multiple versions of the same logical forecast,
leading to meaningless output. Creating/updating/deleting these records directly
can result in the versioning data structure being broken. Instead, we have
services for accessing this data that provide the required semantics.

### Creating forecasts

Most code we write should not need to concern itself with versioning. When
storing forecasts, we just want to say what the value for a given activity and
quarter is. To do that, use the `ForecastHistory` class:

```rb
history = ForecastHistory.new(
  activity,
  financial_quarter: 3,
  financial_year: 2022,
  user: current_user
)
history.set_value(50_000)
```

If you have a `FinancialQuarter` object, you can use that as a parameter:

```rb
quarter = FinancialQuarter.new(2022, 3)
history = ForecastHistory.new(activity, user: current_user, **quarter)
history.set_value(50_000)
```

`ForecastHistory#set_value` uses `ConvertFinancialValue` internally
so it can handle strings including formatting, such as `"£50,000"`. If `user` is
passed, the policies are checked to make sure the requested action is allowed.

This method transparently stores the forecast value in a way that preserves
historical data, and links the forecast to the current editable `Report` that
contains `activity`. The forecast must relate to a quarter _in the future_
relative to the report's date, i.e. the Q3 2022 report may contain forecasts for
Q4 2022 onwards. Violations of this rule will raise
`ForecastHistory::SequenceError`.

If you're creating forecast data in tests, you will need to make sure a `Report`
exists for this data to be added to. Tests relating to forecasts often need to
set up a sequence of reports, creating a report in Q1, approving it, creating
the next report in Q2, and so on. The `ReportingCycle` class exists to make this
easier:

```rb
reporting_cycle = ReportingCycle.new(activity, 3, 2022)

# creates a Q3 2022 report for the organisation and fund that `activity` belongs
# to, and makes it editable
reporting_cycle.tick

# approves the Q3 2022 report and opens the Q4 2022 report
reporting_cycle.tick

# approves Q4 2022 and opens a report for Q1 2023
reporting_cycle.tick

# etc.
```

Normally a `Report` is associated with the financial quarter in which it was
created. Using `ReportingCycle` makes it easy to create reports in specific
quarters without using `travel_to` to move the system clock.

### Querying forecasts

To read forecast data for an activity, use the `ForecastOverview`
class:

```rb
overview = ForecastOverview.new(activity)
forecasts = overview.latest_values
```

`ForecastOverview#latest_values` returns a relation of
`Forecast` objects representing the current versions of the forecasts
for the given `activity`, for each quarter with spending planned. It does not
return any forecasts whose value is `0`, since that represents there being no
spending planned, so calling `ForecastHistory#set_value(0)` has the
effect of deleting a forecast -- it just does it non-destructively, without
deleting historical data.

Accessing the `Forecast` class directly to perform queries will in
general return multiple versions of the same forecast -- records for the same
activity and quarter. So, for example, summing over these to get the total
forecast for an activity is incorrect, because it will count some values that
have been superseded by later versions. Instead, call
`overview.latest_values.sum(:value)` to make sure you only count the latest
version of the forecasts.

`ForecastOverview` can also be given an array of `Activity` IDs, for
when you want to get all the forecasts for a set of activities:

```rb
overview = ForecastOverview.new(activity_ids)
forecasts = overview.latest_values
```

We sometimes need to fetch the versions of the forecasts that were captured in a
certain `Report`, for example when exporting the report as CSV. This is done
using the `snapshot` method:

```rb
overview = ForecastOverview.new(activity_ids)
snapshot = overview.snapshot(Report.last).all_quarters
```

The `Snapshot` class lets you get the value of the forecast spending for a
specific quarter:

```rb
value = snapshot.value_for(financial_year: 2022, financial_quarter: 3)
```

The `all_quarters` call performs a single query to load all the forecasts for
the activity, as of the given report, so we don't perform a query on every call
to `snapshot.value_for`.


## How versioning works

Normally you should just use the services described above to access forecast
data. If you need to work on those services themselves, you'll need to
understand how they store data internally. The first thing to understand is how
reports are sequenced.

### Report sequencing

Reports represent snapshots of the financial information over time. Every
quarter, each partner files a report detailing what they've forecasted and spent
on their activities in that quarter, and they file one report each each fund
they're involved with.

All the reports for a given fund and organisation form a _series_. For example,
"the reports submitted by the UK Space Agency (UKSA) for Newton Fund (NF)" is a
series, with a new report added to the series each quarter. In additional, many
series contain a _historic report_, which represents all the historic data
ingested as part of that partner's onboarding, and isn't associated with a
particular quarter.

So for example, if UKSA was onboarded in Q3 2020, then there will be one
historic report, with no financial quarter, representing all their NF activity
up to Q3 2020. Then in Q3 2020 they begin reporting data through RODA, and so
the Q3 2020 report becomes the second report in this series.

    Report series: UK Space Agency, Newton Fund

    1:  historic report (no quarter)
    2:  Q3 2020
    3:  Q4 2020
    4:  Q1 2021
        etc.

In the code, a report series is all the reports having the same `organisation`
and `fund`. The scope `Report.in_historical_order` encodes this ordering:
reports are sorted in ascending order by their financial quarter, with the
historic report sorted before all others. The database ensure that there is only
one historic report per series. Two reports in the same series may have the same
financial quarter; in such cases their order is decided by their `created_at`
timestamps.

The scope `Report.historically_up_to(report)` selects reports from a series that
are earlier than `report` in this series, including `report` itself. This is
used by the `Snapshot` class to exclude forecasts from later reports when
exporting a specific report as CSV.

For the purposes of versioning, the key property here is that reports in a
series are _totally ordered_: they are sequential and do not represent
overlapping time periods. The reports in a series can be listed in order, and
financial data can be versioned by linking it to reports and using the reports'
sequence order to decide which version is most recent.

### Forecasts at level C/D

Activities at level C and D belong to delivery partners and their data goes
through the assurance process, with the partner submitting quarterly reports
which are checked by BEIS.

A single _logical forecast_ is a plan to spend a certain amount of money on a
particular thing. The _things_ we make forecasts against are activities, broken
down by quarter. So for instance, "the amount of money we plan to spend on
rocket fuel in Q1 2025", is a single logical forecast.

The _value_ of that forecast may change over time, as our plans change. So the
value we record for forecast spend on rocket fuel in Q1 2025 changes in each
report:

    Report series: UKSA, NF     Rocket fuel, Q1 2025

           historic report                  £ 50,000
                   Q3 2020                  £ 64,000
                   Q4 2020                  £ 64,000
                   Q1 2021                  £ 81,000

This series of values for the forecast "rocket fuel in Q1 2025" represent the
_versions_ of the forecast as captured in each subsequent report, and this is
what we store in the `forecasts` table. In general, a
`Forecast` has:

- `parent_activity` - the `Activity` which it concerns
- `financial_quarter`, `financial_year` - the time period when the spending will
  happen
- `value` - the amount of spending that is planned
- `report` - the `Report` this record is linked to

The `parent_activity`, `financial_year` and `financial_quarter` represent the
_subject_ of the forecast, the thing we plan to spend money on. All the
`forecasts` records with equal values for these fields represent
different versions of the same logical forecast. The database ensures that only
one version of a logical report exists for the same report.

The `report` association is used to _order_ the versions when querying them: the
version with value £81,000 is linked to the last report in the series, so it is
the current version of this forecast. Storing all the versions just means we can
reconstruct the data from any previous report, as it was when it was submitted.

The `ForecastHistory` service deals with storing updates to a
forecast non-destructively. Remember its interface:

```rb
quarter = FinancialQuarter.new(2022, 3)
history = ForecastHistory.new(activity, user: current_user, **quarter)
history.set_value(50_000)
```

The `set_value` method checks to see whether a `forecasts` record
exists in the current _editable_ report for `activity`, relating to the given
activity and quarter. If there is one, then we can modify that record's `value`
because the report has not yet been approved and therefore committed to history.
If there is no such record, then we create one.

There are some optimisations in handling `set_value(0)` to avoid storing lots of
redundant `0` values. Essentially if there are no prior versions with non-zero
values, then we can delete any forecast from the current editable report. If
there are prior versions, then we _override_ them by storing a new record with
value `0`.

It is also fine for this sequence to contain gaps. Notice in our example that
the forecast value did not change in the Q4 2020 report -- it remained at
£64,000. This can be handled by not storing a new forecast at all for that
report:

    Report series: UKSA, NF     Rocket fuel, Q1 2025

           historic report                  £ 50,000
                   Q3 2020                  £ 64,000
                   Q4 2020                        --
                   Q1 2021                  £ 81,000

If we want to know the value of the forecast for Q1 2025 rocket fuel spending
was as of the Q4 2020 report, we see that the most recent forecast _before_ that
point in the report sequence was the £64,000 value stored in the Q3 2020 report.

When a user views financial information in the service, they're seeing the
latest available value for each forecast. That value may have been entered many
reports back and not updated since, it is not necessary for every report to hold
a complete copy of all the forecasts, as long as historic data is never
modified.

### Quarters, quarters everywhere

Something that often confuses people when discussing this is that two things in
this model -- forecasts, and reports -- both related to financial quarters.
Talking about the evolution of time-related things over time is confusing. For
example we'll typically have many forecasts for the same activity in different
quarters, each changing in each new report:

    Report series: UKSA, NF     Fuel, Q1 2025   Fuel, Q2 2025   Fuel, Q3 2025

           historic report           £ 15,000        £ 94,000        £ 23,000
                   Q3 2020           £ 79,000        £ 40,000        £ 89,000
                   Q4 2020           £  2,000        £ 82,000        £ 57,000
                   Q1 2021           £ 25,000        £ 22,000        £  4,000

You may find it helpful to remove time _per se_ from this model and focus on the
essential structural properties of the data.

For reports, the financial quarter (or lack of one) just defines the _order_ of
reports belonging to the same fund and organisation, and we can replace them
with sequential numbers.

For forecasts, the financial quarter is part of the _identity_ of the thing
we're planning to spend money on, and we can replace all the different quarters
above with the names of different objects.

    Report series: UKSA, NF           Fuel         Bolts         Paint

                  report #1       £ 15,000      £ 94,000      £ 23,000
                  report #2       £ 79,000      £ 40,000      £ 89,000
                  report #3       £  2,000      £ 82,000      £ 57,000
                  report #4       £ 25,000      £ 22,000      £  4,000
                  report #5            ...           ...           ...
                  etc.

In the first report, we planned to spend £15,000 on fuel, £94,000 on bolts, and
£23,000 on paint. In the second report we revised these plans to £79,000 on
fuel, £40,000 on bolts and £89,000 on paint. In the real world, the _thing_ a
forecast spend relates to is the pair `(activity, financial_quarter)` rather
than a single atomic value, but the idea is the same.

The only meaningful role played by financial quarters is that for any forecast,
its own financial quarter must be in the future relative to the report's
financial quarter. That is, you can't plan to spend money on fuel in Q4 2020, in
a report filed in Q1 2021, because that would be a prediction about the past.

### Forecasts at level A/B

Activities in the upper levels are owned by BEIS and are not subject to
reporting. Financial records for these activities are _not_ linked to reports,
so we do not use the same versioning model. Instead, the versioning for
forecasts is much simpler.

A _logical forecast_ still relates to a certain activity and quarter. When
`ForecastHistory#set_value` is called, we check whether any records
exist for that activity and quarter. If not, we create one with
`forecast_type = :original`. If such a record already exists, we
create a second one with `forecast_type = :revised`. And if a
revised record already exists then we modify its `value`. As such, at most two
records will exist for a given activity and quarter.

The `ForecastOverview` class deals with the different versioning
schemes at different levels, including if you pass a set of IDs for activities
at various levels. Its `latest_values` method will always return the current
versions for each activity.

## Deleting the forecast history

__The only time we ever do this is when the parent activity is being deleted and
so we need to delete the entire history of the forecasts__

Use `unscoped` to bypass our warning on Forecasts.

The steps are:

Get your activity:

```ruby
activity = Activity.find("activity id")
```

Create a `ForecastOverview` for it:

```ruby
overview = ForecastOverview.new(activity)
```

Use `latest_values` to get the 'slice' of history and delete it:

```ruby
overview.latest_values.each { |forecast| Forecast.unscoped.delete(forecast.id)
}
```

Repeat until there are no forecasts returned from `latest_values`
