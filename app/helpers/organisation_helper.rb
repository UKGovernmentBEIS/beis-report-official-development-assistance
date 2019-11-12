# frozen_string_literal: true

module OrganisationHelper
  def yaml_to_options(type)
    yaml = load_yaml(type)
    data = yaml["data"]
    data.collect { |item| [item["name"], item["code"]] }
  end

  def load_yaml(type)
    YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/IATI/#{IATI_VERSION}/organisation/#{type}.yml"))
  end
end
