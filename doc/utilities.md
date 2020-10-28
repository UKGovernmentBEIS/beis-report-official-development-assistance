# Invalid_activities rake task

## Context

We made this task to be able to provide the client with a detailed list of
invalid activities so they could amend each of them. The information on
each CSV row is:
  - Activity organisation name
  - Activity title
  - Activity level
  - Activity URL

The purpose of this task is to be run in production, where the invalid activities
live at the moment.

## Running the task

You can run this task on the console by typing `rake invalid_activities`. This
command will run the task and, once it's finished, you will find the file
`invalid_activities.csv` in the `tmp` folder of this project.
