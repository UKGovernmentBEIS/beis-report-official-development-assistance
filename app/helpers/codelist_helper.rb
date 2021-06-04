# frozen_string_literal: true

module CodelistHelper
  DEVELOPING_COUNTRIES_CODE = "998"

  def default_currency_options
    Codelist.new(type: "default_currency").to_objects
  end

  def currency_select_options
    objects = Codelist.new(type: "default_currency").to_objects(with_empty_item: false)
    objects.unshift(OpenStruct.new(name: "Pound Sterling", code: "GBP")).uniq
  end

  def region_select_options
    objects = Codelist.new(type: "recipient_region").to_objects(with_empty_item: false)
    objects.unshift(OpenStruct.new(name: "Developing countries, unspecified", code: "998")).uniq
  end

  def country_select_options
    objects = Codelist.new(type: "recipient_country").to_objects(with_empty_item: false)
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
    list = Codelist.new(type: "intended_beneficiaries").values.flatten
    list.collect { |item|
      OpenStruct.new(name: item["name"], code: item["code"])
    }.compact.sort_by(&:name)
  end

  def collaboration_type_radio_options
    codelist = Codelist.new(type: "collaboration_type", source: "beis")
    codelist.to_objects(with_empty_item: false).sort_by(&:code)
  end

  def sector_category_radio_options
    Codelist.new(type: "sector_category").to_objects(with_empty_item: false)
  end

  def sector_radio_options(category: nil)
    options = Codelist.new(type: "sector").to_objects_with_categories
    options.each { |option| option.name = "#{option.name} (#{option.code})" }
    if category.present?
      options.filter { |sector| sector.category == category.to_s }
    else
      options
    end
  end

  def gdi_radio_options
    Codelist.new(type: "gdi").to_objects(with_empty_item: false).sort_by(&:code)
  end

  def all_sectors
    Codelist.new(type: "sector").to_objects_with_categories(include_withdrawn: true)
  end

  def aid_types
    @aid_types ||= Codelist.new(type: "aid_type", source: "beis")
  end

  def aid_type_radio_options
    aid_types.to_objects_with_description(
      code_displayed_in_name: true,
    )
  end

  def collaboration_type_from_aid_type(aid_type_code)
    item = aid_types.find_item_by_code(aid_type_code) || {}
    item["collaboration_type"]
  end

  def can_infer_collaboration_type?(aid_type_code)
    collaboration_type_from_aid_type(aid_type_code).present?
  end

  def fstc_from_aid_type(aid_type_code)
    item = aid_types.find_item_by_code(aid_type_code) || {}

    item["ftsc_applies"]
  end

  def can_infer_fstc?(aid_type_code)
    !fstc_from_aid_type(aid_type_code).nil?
  end

  def fstc_applies_radio_options
    [
      OpenStruct.new(value: 0, label: I18n.t("form.label.activity.fstc_applies.false")),
      OpenStruct.new(value: 1, label: I18n.t("form.label.activity.fstc_applies.true")),
    ]
  end

  def policy_markers_radio_options
    options = Codelist.new(type: "policy_significance", source: "beis")
      .to_objects_with_description
      .sort_by { |c| c.code.to_i }

    options.rotate(-1)
  end

  def policy_markers_desertification_radio_options
    options = Codelist.new(type: "policy_significance_desertification", source: "beis")
      .to_objects_with_description
      .sort_by { |c| c.code.to_i }

    options.rotate(-1)
  end

  def programme_status_radio_options
    data = Codelist.new(source: "beis", type: "programme_status")

    Activity.programme_statuses.map do |name, code|
      status = data.find { |d| d["code"] == code }
      OpenStruct.new(value: name, label: status["name"], description: status["description"])
    end
  end

  def iati_status_from_programme_status(programme_status)
    data = Codelist.new(type: "programme_status", source: "beis")

    programme_status_code = Activity.programme_statuses[programme_status]
    status = data.find { |d| d["code"] == programme_status_code }
    status["iati_status_code"].to_s
  end

  def covid19_related_radio_options
    data = Codelist.new(type: "covid19_related_research", source: "beis")
    data.collect { |item|
      OpenStruct.new(code: item["code"], description: item["description"])
    }.compact.sort_by(&:code)
  end

  def gcrf_strategic_area_options
    Codelist.new(type: "gcrf_strategic_area", source: "beis").to_objects_with_description
  end

  def gcrf_challenge_area_options
    data = Codelist.new(type: "gcrf_challenge_area", source: "beis")
    data.collect { |item|
      OpenStruct.new(code: item["code"], description: item["description"])
    }.compact.sort_by { |x| x.code.to_i }
  end

  def fund_pillar_radio_options
    data = Codelist.new(type: "fund_pillar", source: "beis")
    data.collect { |item|
      OpenStruct.new(code: item["code"], description: item["description"])
    }.compact.sort_by(&:code)
  end

  def oda_eligibility_radio_options
    data = Codelist.new(type: "oda_eligibility", source: "beis")

    Activity.oda_eligibilities.map do |name, code|
      options = data.find { |d| d["code"] == code }
      OpenStruct.new(value: name, label: options["name"], description: options["description"])
    end
  end

  def organisation_type_options
    Codelist.new(type: "organisation_type").to_objects
  end

  def language_code_options
    Codelist.new(type: "language_code").to_objects
  end

  def beis_allowed_channel_of_delivery_codes
    Codelist.new(type: "channel_of_delivery_code", source: "beis").list
  end

  def channel_of_delivery_codes
    iati_data = Codelist.new(type: "channel_of_delivery_code")
    beis_allowed_codes = beis_allowed_channel_of_delivery_codes

    iati_data.select { |item|
      item["code"].in?(beis_allowed_codes)
    }.map { |item|
      OpenStruct.new(name: "#{item["code"]}: #{item["name"]}", code: item["code"])
    }
  end

  def budget_type_options
    Codelist.new(type: "budget_type", source: "beis").to_objects_with_description
  end
end
