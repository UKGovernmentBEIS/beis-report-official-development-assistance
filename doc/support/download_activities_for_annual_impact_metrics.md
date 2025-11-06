# Download activities for annual impact metrics

Every July, support will need to generate a CSV of activities that will be used
to pre-populate an annual collaborative spreadsheet of fund impact metrics.

1. Connect to the production environment using SSH. See [console
   access](/doc/console-access.md).
   ```shell
   cf ssh beis-roda-prod
   ```
2. Run the [annual fund impact metrics Rails
   task](/lib/tasks/annual_fund_impact_metrics_activities.rake). This will
   generate a CSV file containing Level D activities (or C, for specified
   organisations) for each Organisation, written to
   `tmp/annual_fund_impact_metrics`. Note: if this task has
   been run before, the previous CSVs will be overwritten; you must make sure
   the CSV you download is not a previous iteration.

   This takes an array of integer Financial Years to specify for which years the
   Activities should be collected.
   ```shell
   bin/rails activities:annual_fund_impact_metrics[2021,2022,2023,2024]
   ```
3. Wait for the Rails task to finish, then end the SSH session.
   ```shell
   exit
   ```
4. Copy the directory to your local machine.
   ```shell
    cf ssh beis-roda-prod --command "tar czf - /app/tmp/annual_fund_impact_metrics" > annual_fund_impact_metrics.tar.gz
   ```

