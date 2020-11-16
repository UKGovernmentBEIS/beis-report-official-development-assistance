# frozen_string_literal: true

module CodelistHelper
  DEVELOPING_COUNTRIES_CODE = "998"
  AFRICA_REGIONAL_SUBREGIONS = [
    "1027",
    "1028",
    "189",
    "1029",
    "1030",
  ]
  SOUTH_SAHARA_SUBREGIONS = [
    "1027",
    "1028",
    "1029",
    "1030",
  ]
  AMERICA_REGIONAL_SUBREGIONS = [
    "1031",
    "1032",
    "489",
  ]
  NORTH_AND_CENTRAL_AMERICA_REGIONAL_SUBREGIONS = [
    "1031",
    "1032",
  ]
  ASIA_REGIONAL_SUBREGIONS = [
    "789",
    "589",
    "689",
  ]
  CENTRAL_ASIA_REGIONAL_SUBREGIONS = [
    "689",
  ]
  SOUTH_ASIA_REGIONAL_SUBREGIONS = [
    "689",
  ]
  OCEANIA_REGIONAL_SUBREGIONS = [
    "1033",
    "1034",
    "1035",
  ]
  ALLOWED_AID_TYPE_CODES = [
    "B02",
    "B03",
    "C01",
    "D01",
    "D02",
    "E01",
    "G01",
  ]

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

  def yaml_to_objects_with_description(entity:, type:, code_displayed_in_name: false)
    data = load_yaml(entity: entity, type: type)
    return [] if data.empty?

    data = data.collect { |item|
      name = code_displayed_in_name ? "#{item["name"]} (#{item["code"]})" : item["name"]
      description = t("form.label.#{entity}.#{type}.#{item["code"]}", default: item["description"])

      OpenStruct.new(name: name, code: item["code"], description: description)
    }

    data.sort_by(&:code)
  end

  def yaml_to_objects_with_categories(entity:, type:, include_withdrawn: false)
    data = load_yaml(entity: entity, type: type)
    return [] if data.empty?

    data.collect { |item|
      next if item["status"] == "withdrawn" && include_withdrawn == false
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

  def region_name_from_code(code)
    region = region_select_options.find { |option| option.code == code }
    return "" unless region
    region.name
  end

  def country_name_from_code(code)
    country = country_select_options.find { |option| option.code == code }
    return "" unless country
    country.name
  end

  def intended_beneficiaries_checkbox_options
    recipient_region = @activity.recipient_region
    list = load_yaml(entity: "activity", type: "intended_beneficiaries")
    show_list = if recipient_region == DEVELOPING_COUNTRIES_CODE || @activity.recipient_country?
      list.values.flatten
    elsif recipient_region == "298" # Africa, regional
      AFRICA_REGIONAL_SUBREGIONS.map { |subregion| list[subregion] }.flatten
    elsif recipient_region == "289" # South of Sahara
      SOUTH_SAHARA_SUBREGIONS.map { |subregion| list[subregion] }.flatten
    elsif recipient_region == "498" # America, regional
      AMERICA_REGIONAL_SUBREGIONS.map { |subregion| list[subregion] }.flatten
    elsif recipient_region == "389" # North & Central America, regional
      NORTH_AND_CENTRAL_AMERICA_REGIONAL_SUBREGIONS.map { |subregion| list[subregion] }.flatten
    elsif recipient_region == "798" # Asia, regional
      ASIA_REGIONAL_SUBREGIONS.map { |subregion| list[subregion] }.flatten
    elsif recipient_region == "619" || recipient_region == "679" # Central Asia, regional and South Asia, regional. No matching countries as single regions so mapping to South & Central Asia instead
      list["689"]
    elsif recipient_region == "889" # Oceania, regional
      OCEANIA_REGIONAL_SUBREGIONS.map { |subregion| list[subregion] }.flatten
    else
      list[recipient_region]
    end
    show_list.collect { |item|
      OpenStruct.new(name: item["name"], code: item["code"])
    }.compact.sort_by(&:name)
  end

  def collaboration_type_radio_options
    yaml_to_objects(entity: "activity", type: "collaboration_type", with_empty_item: false).sort_by(&:code)
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

  def gdi_radio_options
    yaml_to_objects(entity: "activity", type: "gdi", with_empty_item: false).sort_by(&:code)
  end

  def all_sectors
    yaml_to_objects_with_categories(entity: "activity", type: "sector", include_withdrawn: true)
  end

  def aid_type_radio_options
    options = yaml_to_objects_with_description(
      entity: "activity",
      type: "aid_type",
      code_displayed_in_name: true
    )

    options.select { |a| ALLOWED_AID_TYPE_CODES.include?(a.code) }
  end

  def load_yaml(entity:, type:)
    yaml = YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/IATI/#{IATI_VERSION}/#{entity}/#{type}.yml"))
    yaml["data"]
  rescue
    []
  end
end
