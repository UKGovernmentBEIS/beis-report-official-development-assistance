# Run me with `rails runner db/data/20240123152048_change_beis_to_dsit.rb`

service_owner = Organisation.where(iati_reference: ["GB-GOV-13", "GB-GOV-26"]).first
if service_owner
  service_owner.iati_reference = "GB-GOV-26"
  service_owner.name = "DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY"
  service_owner.beis_organisation_reference = "DSIT"
  service_owner.alternate_names = [
    "DEPARTMENT FOR SCIENCE, INNOVATION & TECHNOLOGY",
    "Department for Science, Innovation and Technology",
    "Department for Science, Innovation & Technology"
  ]

  unless service_owner.save
    puts "Failed to save the changes to #{service_owner.name}: #{service_owner.errors.messages.inspect}"
  end
end

finance = Organisation.where(iati_reference: "GB-GOV-13-OPERATIONS").first
if finance
  finance.iati_reference = "GB-GOV-26-OPERATIONS"
  finance.name = "DSIT FINANCE"
  finance.beis_organisation_reference = "DF"

  unless finance.save
    puts "Failed to save the changes to #{finance.name}: #{finance.errors.messages.inspect}"
  end
end
