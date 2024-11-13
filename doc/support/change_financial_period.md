# Change a report's financial period

The financial year and financial quarter can only be set when creating a report.
There are read-only constraints at database level to prevent the dates being changed
through the website.

If somehow a report was created with the wrong dates, they can only be corrected by
editing the report in question in a Rails console and bypassing validation, e.g.

```ruby
report = Report.find("abc123")
Report.where(id: report.id).update_all(financial_quarter: 2, financial_year: 2021)
```
