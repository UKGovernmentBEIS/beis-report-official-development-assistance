# 29. Application text encoding

Date: 2021-02-16

## Status

Accepted

## Context

The application accepts user data both in the forms shown on web pages and in
csv files that are uploaded.

One of the most common applications our users utilise for preparing their data
is Microsoft Excel. Excel follows a non-standardised way of identifying utf-8
encoded text. It includes a 'byte order mark' (bom) at the start of the file when
saving as utf-8, it also looks for the bom when opening a file in order to
identify the encoding.

## Decision

As per the GDS guidance on encoding text, the application expect users to
provide unicode text encoded in utf-8.

https://www.gov.uk/government/publications/open-standards-for-government/cross-platform-character-encoding-profile

To best help our users, the application will handle the bom in Excel files
and add the bom when exporting its own csv files encoded in utf-8.

## Consequences

For some uses this means when saving the csv files they wish to upload they must
ensure the file is encoded correctly, usually by 'saving as' utf-8 encoded text.

By handling and adding the bom to in files,  we can be confident that our users
will experience the least friction when using the application.

We will use the service documentation as an opportunity to help users understand
these requirements.
