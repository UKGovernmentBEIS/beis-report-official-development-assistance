# Run me with `rails runner db/data/20221019111441_add_ispf_level_a_activity.rb`

# Add the top level (A) ISPF Activity (i.e. a fund-tier activity)

beis = Organisation.service_owner

description = <<~TXT.squish
  ISPF exists to enable potential and foster prosperity, 
  by funding research and innovation on the major themes of our time. 
  By working with partners to support research excellence. 
  By building the knowledge and technology of tomorrow. 
  By complementing strong ties with countries that share our values. 
  By helping researchers and innovators to cultivate connections, 
  follow their curiosity and pioneer transformations internationally. 
  For the good of the planet.
TXT

Activity.create!(
  source_fund_code: 4,
  roda_identifier: "ISPF",
  title: "International Science Partnerships Fund",
  organisation: beis,
  level: "fund",
  form_state: "complete",
  fstc_applies: false,
  partner_organisation_identifier: "ISPF",
  description: description,
  sector_category: "998",
  sector: "99810",
  programme_status: "spend_in_progress",
  actual_start_date: Date.new(2022, 4, 1),
  aid_type: "C01"
)
