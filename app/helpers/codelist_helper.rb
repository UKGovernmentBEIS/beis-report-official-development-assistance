# frozen_string_literal: true

module CodelistHelper
  # TODO: Remove `yaml_to_options` when all forms are migrated from simple form to the govuk form builder,
  # The govuk form builder expects an array of objects, not an array of arrays.
  def yaml_to_options(entity, type)
    data = load_yaml(entity, type)
    return [] if data.empty?

    data.collect { |item| [item["name"], item["code"]] }.sort
  end

  def yaml_to_objects(entity, type, with_empty_item = true)
    data = load_yaml(entity, type)
    return [] if data.empty?

    objects = data.collect { |item| OpenStruct.new(name: item["name"], code: item["code"]) }.sort_by(&:name)
    if with_empty_item
      empty_item = OpenStruct.new(name: "", code: "")
      objects.unshift(empty_item)
    end
    objects
  end

  def load_yaml(entity, type)
    yaml = YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/IATI/#{IATI_VERSION}/#{entity}/#{type}.yml"))
    yaml["data"]
  rescue
    []
  end
end
