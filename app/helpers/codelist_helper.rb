# frozen_string_literal: true

module CodelistHelper
  def yaml_to_options(entity, type)
    yaml = load_yaml(entity, type)
    data = yaml["data"]
    data.collect { |item| [item["name"], item["code"]] }.sort
  end

  def load_yaml(entity, type)
    YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/IATI/#{IATI_VERSION}/#{entity}/#{type}.yml"))
  end
end
