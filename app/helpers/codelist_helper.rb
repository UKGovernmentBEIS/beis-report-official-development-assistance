# frozen_string_literal: true

module CodelistHelper
  def yaml_to_objects(entity:, type:, with_empty_item: true)
    data = load_yaml(entity: entity, type: type)
    return [] if data.empty?

    objects = data.collect { |item|
      next if item["status"] == "withdrawn"
      OpenStruct.new(name: item["name"], code: item["code"])
    }.compact.sort_by(&:name)

    if with_empty_item
      empty_item = OpenStruct.new(name: "", code: "")
      objects.unshift(empty_item)
    end
    objects
  end

  def yaml_to_objects_with_description(entity:, type:)
    data = load_yaml(entity: entity, type: type)
    return [] if data.empty?

    data.collect { |item| OpenStruct.new(name: item["name"], code: item["code"], description: item["description"]) }.sort_by(&:code)
  end

  def yaml_to_objects_with_categories(entity:, type:)
    data = load_yaml(entity: entity, type: type)
    return [] if data.empty?

    data.collect { |item|
      next if item["status"] == "withdrawn"
      OpenStruct.new(name: item["name"], code: item["code"], category: item["category"])
    }.compact.sort_by(&:name)
  end

  def currency_select_options
    objects = yaml_to_objects(entity: "generic", type: "default_currency", with_empty_item: false)
    objects.unshift(OpenStruct.new(name: "Pound Sterling", code: "GBP")).uniq
  end

  def region_select_options
    objects = yaml_to_objects(entity: "activity", type: "recipient_region", with_empty_item: false)
    objects.unshift(OpenStruct.new(name: "Developing countries, unspecified", code: "998")).uniq
  end

  def country_select_options
    objects = yaml_to_objects(entity: "activity", type: "recipient_country", with_empty_item: false)
    objects.unshift(OpenStruct.new(name: I18n.t("page_content.activity.recipient_country.default_selection_value"), code: "")).uniq
  end

  def flow_select_options
    objects = yaml_to_objects(entity: "activity", type: "flow", with_empty_item: false)
    objects.unshift(OpenStruct.new(name: "ODA", code: "10")).uniq
  end

  def sector_category_radio_options
    yaml_to_objects(entity: "activity", type: "sector_category", with_empty_item: false)
  end

  def sector_radio_options(category: nil)
    options = yaml_to_objects_with_categories(entity: "activity", type: "sector")
    if category.present?
      options.filter { |sector| sector.category == category.to_s }
    else
      options
    end
  end

  def load_yaml(entity:, type:)
    yaml = YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/IATI/#{IATI_VERSION}/#{entity}/#{type}.yml"))
    yaml["data"]
  rescue
    []
  end
end
