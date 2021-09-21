# Benefittting countries and regions

## In a wider context
The whole concept of geography is an important one in ODA management. The
countries an activity is seen to benefit is one of the primary factors that make
the activity eligible for ODA funding.

Countries 'graduate' from the eligibility list meaning they are no longer
eligible for ODA funding.

## Benefitting country
Each benefitting country comes from a code list defined by BEIS (via OECD) which
includes the code, naming, region membership and graduation status:

[benefitting_countries.yml](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/438bbd01879310a1dd3dbc1945f3241efa84c550/vendor/data/codelists/BEIS/benefitting_countries.yml)

The application collects and stores any number of benefitting countries in
`benefitting_countries` an attribute of an `Activity`.

When rendering any view, all records are applicable regardless of graduation
status as we may be rendering historical activities.

When collecting new records, only non graduated countries are valid.

Applicable countries are easily accessed via `BenefittingCountry`:

`BenefittingCountry.all`  
`BenefittingCountry.non_graduated`

Based on the benefitting countries assigned to an activity, we can derive the
region, see below.

## Benefitting region
Is calculated based on an activity's benefitting countries. It always results in
one single region being returned to cover the chosen countries.

The region is not stored, it is calculated based on the current benefitting
countries.

The regions and levels are loaded at application boot from the following code
lists:

[benefitting_region_levels.yml](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/d600961262af29677bf9385834f20c55a30bcb8f/vendor/data/codelists/BEIS/benefitting_region_levels.yml)

[benefitting_regions.yml](https://github.com/UKGovernmentBEIS/beis-report-official-development-assistance/blob/d600961262af29677bf9385834f20c55a30bcb8f/vendor/data/codelists/BEIS/benefitting_regions.yml)

The regions are defined be BEIS (via OECD), a sample of which is show below:

| Region   | Sub-region 1    | Sub-region 2    | Country  |
| ---      | ---             | ---             | ---      |
| Africa   | North of Sahara | North of Sahara | Egypt    |
| Africa   | South of Sahara | Middle Africa   | Gabon    |
| Africa   | South of Sahara | Southern Africa | Botswana |
| Africa   | South of Sahara | Southern Africa | Namibia  |
| Americas | South America   | South America   | Brazil   |

Example calculations of a benefitting region value:

- Egypt + Gabon = **Africa** (Region level)
- Gabon + Botswana = **South of Sahara** (Sub-region 1 level)
- Botswana + Namibia = **Southern Africa** (Sub-region 2 level)
- Egypt + Brazil = **Developing countries, unspecified** (> 1 top level
  region)

'Developing countries, unspecified' is a special case where so many countries
benefit that they span multiple regions.

Where an existing activity has `recipient_region` but no `recipient_country` and
no `intended_beneficiaries`, we:

- leave the new `benefitting_countries` field empty
- report the `region` as set in `Activity#recipient_region`

This is the case for a number of historical activities, see below.

## Historically in the application
A significant number of activities have their geography stored using a prior model
made up of:

`Activity::recipient_region`  
`Activity::recipient_country`  
`Activity::intended_beneficiaries`

The logic for this was

- users selects either recipient region or recipient country geography, stored
  as `geography`
- based on that, users select one region or country including a catch all region
  know as 'Developing countries, unspecified'
- users are asked if they wish to add more countries regardless of the responses
  above, this is stored as `requires_additional_benefitting_countries`
- user can choose any number of countries as the `intended_beneficiaries`

All of this data is now read only and kept, the rational for keeping it around
is:

- for an closed (or completed) activity there is no appetite to update the data
  as there is little value in doing so
- for an activity with recipient region we do not know if the intent is 'all
  countries in the region' or 'some countries from that region' and so we cannot
  migrate to the new fields
- we require recipient region in these cases to calculate the region

As the service matures and the data with it, we may be able to remove some of
these columns.
