# frozen_string_literal: true

module CodelistHelper
  class UnreadableCodelist < StandardError; end
  class UnrecognisedSource < StandardError; end

  DEVELOPING_COUNTRIES_CODE = "998"
  ALLOWED_AID_TYPE_CODES = [
    "B02",
    "B03",
    "C01",
    "D01",
    "D02",
    "E01",
    "G01",
  ]
  FSTC_FROM_AID_TYPE_CODE = {
    "D02" => true,
    "E01" => true,
    "G01" => false,
  }

  ALLOWED_POLICY_MARKERS_SIGNIFICANCES = [
    "0",
    "1",
    "2",
    "3",
  ]

  def yaml_to_objects(entity:, type:, with_empty_item: true)
    data = load_yaml(entity: entity, type: type)
    raise UnreadableCodelist if data.empty?

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
    raise UnreadableCodelist if data.empty?

    data = data.collect { |item|
      name = code_displayed_in_name ? "#{item["name"]} (#{item["code"]})" : item["name"]
      description = t("form.hint.#{entity}.options.#{type}.#{item["code"]}", default: item["description"])

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
    list = load_yaml(entity: "activity", type: "intended_beneficiaries").values.flatten
    list.collect { |item|
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

  def fstc_from_aid_type(aid_type_code)
    FSTC_FROM_AID_TYPE_CODE[aid_type_code]
  end

  def can_infer_fstc?(aid_type_code)
    FSTC_FROM_AID_TYPE_CODE.key?(aid_type_code)
  end

  def policy_markers_select_options
    objects = yaml_to_objects(entity: "activity", type: "policy_markers", with_empty_item: false)
    not_assessed_option = OpenStruct.new(name: "Not assessed", code: "1000")

    filtered_list = objects.select { |object| ALLOWED_POLICY_MARKERS_SIGNIFICANCES.include?(object.code) }.sort_by(&:code)
    filtered_list.unshift(not_assessed_option)
  end

  def programme_status_radio_options
    data = load_yaml(entity: "activity", type: "programme_status", source: "beis")

    Activity.programme_statuses.map do |name, code|
      status = data.find { |d| d["code"] == code }
      OpenStruct.new(value: name, label: status["name"], description: status["description"])
    end
  end

  def iati_status_from_programme_status(programme_status)
    data = load_yaml(entity: "activity", type: "programme_status", source: "beis")

    programme_status_code = Activity.programme_statuses[programme_status]
    status = data.find { |d| d["code"] == programme_status_code }
    status["iati_status_code"].to_s
  end

  def covid19_related_radio_options
    data = load_yaml(entity: "activity", type: "covid19_related_research", source: "beis")
    data.collect { |item|
      OpenStruct.new(code: item["code"], description: item["description"])
    }.compact.sort_by(&:code)
  end

  def gcrf_challenge_area_options
    data = load_yaml(entity: "activity", type: "gcrf_challenge_area", source: "beis")
    data.collect { |item|
      OpenStruct.new(code: item["code"], description: item["description"])
    }.compact.sort_by { |x| x.code.to_i }
  end

  def fund_pillar_radio_options
    data = load_yaml(entity: "activity", type: "fund_pillar", source: "beis")
    data.collect { |item|
      OpenStruct.new(code: item["code"], description: item["description"])
    }.compact.sort_by(&:code)
  end

  def oda_eligibility_radio_options
    data = load_yaml(entity: "activity", type: "oda_eligibility", source: "beis")

    Activity.oda_eligibilities.map do |name, code|
      options = data.find { |d| d["code"] == code }
      OpenStruct.new(value: name, label: options["name"], description: options["description"])
    end
  end

  def load_yaml(entity:, type:, source: "iati")
    raise UnrecognisedSource unless source.in?(%w[iati beis])

    yaml = if source == "iati"
      YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/IATI/#{IATI_VERSION}/#{entity}/#{type}.yml"))
    else
      YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/BEIS/#{type}.yml"))
    end
    yaml["data"]
  rescue
    []
  end
end
