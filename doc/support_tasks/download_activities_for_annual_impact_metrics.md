NOTE: This document is deprecated. It will be updated with the new process in due time.

# Download activities for annual impact metrics

Every July, support will need to generate a CSV of activities that will be used
to pre-populate an annual collaborative spreadsheet of fund impact metrics.

1. Connect to the production environment using SSH. See [console
   access](/doc/console-access.md).
   ```shell
   cf ssh beis-roda-prod
   ```
2. Run the [annual fund impact metrics Rails
   task](/lib/tasks/annual_fund_impact_metrics_activities.rake). The resulting CSV
   will be written to `tmp/annual_fund_impact_metrics.csv`. Note: if this task has
   been run before, the previous CSV will be overwritten; you must make sure the
   CSV you download is not a previous iteration.
   ```shell
   bin/rails activities:annual_fund_impact_metrics
   ```
3. Wait for the Rails task to finish, then end the SSH session.
   ```shell
   exit
   ```
4. Copy the file to your local machine See [uploading and downloading
   files](/doc/uploading-and-downloading-files.md).
   ```shell
   cf ssh beis-roda-prod --command "cat /app/tmp/annual_fund_impact_metrics.csv" >
   local_file.csv
   ```

