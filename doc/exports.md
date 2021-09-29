# Exports

## Spending Breakdown
A report primarily aimed at BEIS finance needs.

- Includes all __Actual spend__ at the time the export is created
- Includes all __Refunds__ at the time the export is created
- Actual spend includes adjustments for the same financial quarter and of `type`
  `Actual`
- Refunds includes adjustments for the same financial quarter and of `type`
  `Refund`
- Actual spend, Refunds and Adjustments share the same `Transaction` base class
  and database table
- Includes a net total, the result of summing the Actual spend and Refund totals
- Includes all `Forecast` for financial quarters not already included with Actual
  spend and refunds at the time the export is created
- Forecasts are already stored as a total for the activity and financial quarter

### Example calculation

```
Q1 2021-2022 values
---------------------------------
Actual spend:              10,000
Actual spend:               5,000
Adjustment (type: Actual): -1,000
Refund:                    -5,000
Adjustment (type: Refund):  1,000
Adjustment (type: Actual):    500
Adjustment (type: Refund):    -50
---------------------------------
Actual spend total:        14,500
Refund total:              -4,050
Net total:                 10,450
```

### BEIS users
- Can download a file per __Fund__ containing all delivery partner
organisation activities, this export is expensive to run and takes time.
- Can download a file per __Fund__ containing only a single delivery partner
  organisation activities

### Delivery partner users
- Can download an export per __Fund__ containing only their own associated
  organisation activities
