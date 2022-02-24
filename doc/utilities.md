# Invalid_activities rake task

## Context

We made this task to be able to provide the client with a detailed list of
invalid activities so they could amend each of them. The information on
each CSV row is:
  - Activity organisation name
  - Activity title
  - Activity level
  - Activity URL
  - Validation Errors, one per column

Each error during validation appears in its own column for ease of manipulation
in a spreadsheet, and consists of the affected field plus the error message.

The purpose of this task is to be run in production, where the invalid activities
live at the moment.

## Running the task

You can run this task on the console by typing `rake activities:invalid`. This
command will run the task and, once it's finished, you will find the file
`invalid_activities.csv` in the `tmp` folder of this project.
