# Creating a new report
Very rarely a new Delivery partner organisation may join BEIS ODA reporting.

When this happens a developer will be required to 'seed' the new reports into
the database for the new organisation.

Once the seed is planted, no further developer action is required as all
subsequent reports are created automatically.

This request should come through as a support ticket and will need to clearly
indicate the new delivery partner organisation that must have been created by
BEIS already and which fund/s to create the report for, at the time of
writing there are only two options: Newton fund or Global Challenges Research
Fund (GCRF).

## Process

### Prerequisites
- [Console access](../console-access.md)
- The Delivery partner organisation
- The funds to create the reports for

### Steps
Get access to the Rails console in production, see [console
access](../console-access.md)

Get the Delivery partner organisation id, one approach is to list all the
delivery partner organisations and find the id of the one in question:

```
Organisation.delivery_partner

organisation = Organisation.find("{id}")
```

Get the funds so you have access to their ids:

```
gcrf_fund = Fund.by_short_name("GCRF").activity
newton_fund = Fund.by_short_name("NF").activity
```

Create the new reports:

```
Report.create(organisation_id: organisation.id, fund_id: gcrf_fund.id)
Report.create(organisation_id: organisation.id, fund_id: newton_fund.id)
```

Confirm the reports:

```
Report.where(organisation_id: organisation.id)
```

You should see the new reports, something like:

```
[#<Report:0x0000556bdc6cf258
  id: "4b5115ca-d791-4b8d-8e62-57d49c44a949",
  state: "inactive",
  description: nil,
  fund_id: "4c7db46e-3ac0-49e5-840f-ff9f7ece883f",
  organisation_id: "b51fa616-de29-46db-8af0-6e5f38e50591",
  created_at: Thu, 30 Sep 2021 08:10:26.009937000 UTC +00:00,
  updated_at: Thu, 30 Sep 2021 08:10:26.009937000 UTC +00:00,
  deadline: nil,
  financial_quarter: 2,
  financial_year: 2021>,
 #<Report:0x0000556bdc6cf0c8
  id: "25af4dbe-7ec6-4db1-b003-2c2b595e78f9",
  state: "inactive",
  description: nil,
  fund_id: "e85338e7-f4ab-4b19-8173-3ea84e90b20d",
  organisation_id: "b51fa616-de29-46db-8af0-6e5f38e50591",
  created_at: Thu, 30 Sep 2021 08:10:34.585764000 UTC +00:00,
  updated_at: Thu, 30 Sep 2021 08:10:34.585764000 UTC +00:00,
  deadline: nil,
  financial_quarter: 2,
  financial_year: 2021>]
  ```
