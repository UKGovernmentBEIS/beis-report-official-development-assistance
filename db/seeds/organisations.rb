require "yaml"

organisations = YAML.safe_load(File.read(File.join(Rails.root, "db", "seeds", "organisations.yml")))
organisations.each do |organisation|
  organisation_params = {
    name: organisation["name"],
    beis_organisation_reference: organisation["short_name"],
    organisation_type: organisation["type"],
    language_code: "en",
    default_currency: "gbp",
    role: organisation["role"],
  }
  Organisation.find_or_create_by(iati_reference: organisation["reference"]).update!(organisation_params)
end
