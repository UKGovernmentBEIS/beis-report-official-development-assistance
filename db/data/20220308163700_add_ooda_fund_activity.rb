# Add the top level (A) Other ODA Activity (i.e. a fund-tier activity)

beis = Organisation.service_owner

description = <<~TXT.squish
  Other ODA represents spending from ‘other non ODA budgets from BEIS’ which may be
  classed as ‘ODA spend’ i.e. is ODA-eligible in the same way as spend from the
  Newton Fund and GCRF.
TXT

Activity.create!(
  source_fund_code: 3,
  roda_identifier: "OODA",
  title: "Other ODA",
  organisation: beis,
  level: "fund",
  form_state: "complete", # wizard progress
  fstc_applies: false, # free_standing_technical_cooperation: false,
  delivery_partner_identifier: "OODA",
  description: description,
  sector_category: "998", # 510, 998 for NF/GCRF (based on GCRF)
  sector: "99810", # focus area, # 51010, 99810 for NF/GCRF (based on GCRF)
  programme_status: "spend_in_progress", # as NF/GCRF
  actual_start_date: Date.new(2015, 4, 1),
  aid_type: "C01" # same as NF/GCRF
)
