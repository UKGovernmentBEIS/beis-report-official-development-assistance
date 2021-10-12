# Change a report's financial period

New reports are created automatically when earlier reports are approved. For
example if I have a GCRF Q1 report in a submitted state, once it is approved, a
new GCRF report for Q2 will be automatically created. However, if my Q1 report
is not approved before the start of Q3, the automatically generated report will
be assigned to Q3 rather than Q2, which is almost certainly wrong.

To correct this it's necessary to edit the report in question in a Rails
console. Due to 'read-only' constraints on reports it's necessary to bypass
validation, e.g.

```ruby
report = Report.find("abc123")
Report.where(id: report.id).update_all(financial_quarter: 2, financial_year: 2021)
```

