# 37. Use csv-safe to process CSV files

Date: 2023-03-22

## Status

Accepted

## Context

RODA reads and generates CSV files containing user input. If this user input contains malicious code, it could compromise the machines of the users opening CSV files in applications such as Microsoft Excel.

## Decision

We will use the gem `csv-safe` as a replacement for the `csv` gem when generating CSV files.

We will patch the `csv-safe` gem so that it doesn't sanitise string fields consisting only of characters valid in the context of monetary values (digits, `-`, `,` and `.`).

## Consequences

The output is sanitised to make CSV files safer for end users.

We might need to fork and maintain the gem ourselves if its original maintainers abandon it.

We need to maintain the patch in case the gem changes its internal implementation.
