# frozen_string_literal: true

module CodelistHelper
  def default_currency_options
    Codelist.new(type: "default_currency").to_objects
  end

  def region_name_from_code(code)
    recipient_regions = Codelist.new(type: "recipient_region").to_objects(with_empty_item: false)
      .unshift(OpenStruct.new(name: "Developing countries, unspecified", code: "998")).uniq

    region = recipient_regions.find { |option| option.code == code }
    return "" unless region
    region.name
  end

  def country_name_from_code(code)
    country = Codelist.new(type: "recipient_country").to_objects(with_empty_item: false)
      .find { |option| option.code == code }

    return "" unless country
    country.name
  end

  def collaboration_type_radio_options
    codelist = Codelist.new(type: "accepted_collaboration_types_and_channel_of_delivery_mapping", source: "beis")
    codelist.to_objects(with_empty_item: false).sort_by(&:code)
  end

  def sector_category_radio_options
    list = Codelist.new(type: "sector_category").to_objects(with_empty_item: false)
    list.each { |item| item.name = "#{item.code}: #{item.name}" }
  end

  def sector_radio_options(category: nil)
    options = Codelist.new(type: "sector").to_objects_with_categories
    options.each { |option| option.name = "#{option.code}: #{option.name}" }
    if category.present?
      options.filter { |sector| sector.category == category.to_s }
    else
      options
    end
  end

  def gdi_radio_options
    Codelist.new(type: "gdi").to_objects(with_empty_item: false).sort_by(&:code)
  end

  def aid_type_radio_options
    @aid_types ||= Codelist.new(type: "aid_type", source: "beis")

    @aid_types.to_objects_with_description(
      code_displayed_in_name: true
    )
  end

  def fstc_applies_radio_options
    [
      OpenStruct.new(value: 0, label: I18n.t("form.label.activity.fstc_applies.false")),
      OpenStruct.new(value: 1, label: I18n.t("form.label.activity.fstc_applies.true"))
    ]
  end

  def policy_markers_radio_options
    data = Codelist.new(type: "policy_significance", source: "beis")

    # all enums except desertification use the same set of names
    Activity.policy_marker_genders.map do |name, code|
      options = data.find { |d| d["code"] == code.to_s }
      # we need e.g. "significant_objective" as the value and "Significant objective" as the label
      # the code is just the connection between the enum and the BEIS codelist
      OpenStruct.new(value: name, label: options["name"], description: options["description"])
    end
  end

  def policy_markers_desertification_radio_options
    data = Codelist.new(type: "policy_significance_desertification", source: "beis")

    Activity.policy_marker_desertifications.map do |name, code|
      options = data.find { |d| d["code"] == code.to_s }
      OpenStruct.new(value: name, label: options["name"], description: options["description"])
    end
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

  def ispf_themes_options
    Codelist.new(type: "ispf_themes", source: "beis").to_objects_with_description
  end

  def ispf_partner_country_options(oda:, allow_none: true)
    type = oda ? "oda" : "non_oda"
    data = Codelist.new(type: "ispf_#{type}_partner_countries", source: "beis")

    data.map do |option|
      next if option["code"] == "NONE" && !allow_none

      OpenStruct.new(code: option["code"], name: option["name"])
    end.compact
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
    Codelist.new(type: "accepted_channel_of_delivery_codes", source: "beis").list
  end

  def channel_of_delivery_codes(activity = nil)
    iati_data = Codelist.new(type: "channel_of_delivery_code")
    inferred_codes = activity && Activity::Inference.service.allowed_values(activity, :channel_of_delivery_code)
    allowed_codes = inferred_codes || beis_allowed_channel_of_delivery_codes

    iati_data.select { |item|
      item["code"].in?(allowed_codes)
    }.map { |item|
      OpenStruct.new(name: "#{item["code"]}: #{item["name"]}", code: item["code"])
    }
  end

  def budget_type_options
    Budget.budget_types.keys.map do |key|
      OpenStruct.new(name: t("form.label.budget.budget_type.#{key}"), code: key, description: t("form.hint.budget.budget_type.#{key}"))
    end
  end

  def tags_options
    Codelist.new(type: "tags", source: "beis").to_objects_with_description
  end
end
