class IngestCsvRow
  attr_accessor :attributes, :updated_attributes

  include CodelistHelper

  def initialize(row = {})
    self.attributes = row.to_h
    self.updated_attributes = {}
  end

  def call
    attributes.each do |name, value|
      method_name = "process_#{name}"

      # Convert weird whitespace to regular spaces
      value = value.gsub(/[[:space:]]/, " ").strip if value.is_a?(String)

      updated_attributes[name] = if respond_to?(method_name)
        send(method_name, value)
      else
        value
      end
    end

    # Set call_present to false if it wasn't already set, and the relevant attributes were passed in
    if updated_attributes.key?("call_open_date") || updated_attributes.key?("call_close_date")
      updated_attributes["call_present"] ||= false
    end

    # Return the processed set of attributes
    updated_attributes
  end

  def process_call_open_date(value)
    return :skip if value.blank? || value.downcase == "n/a" || value.downcase == "not applicable"

    updated_attributes["call_present"] = true
    Date.parse(value)
  end

  def process_call_close_date(value)
    return :skip if value.blank? || value.downcase == "n/a" || value.downcase == "not applicable"

    updated_attributes["call_present"] = true
    Date.parse(value)
  end

  def process_programme_status(value)
    mapped_programme_status = programme_status_mapping.fetch(value.to_s.downcase)
    updated_attributes["status"] = ProgrammeToIatiStatus.new.programme_status_to_iati_status(mapped_programme_status)

    mapped_programme_status
  end

  def process_oda_eligibility(value)
    return false if value.nil?

    value.downcase == "eligible"
  end

  def process_gdi(value)
    value = value.to_s.strip.downcase
    return nil if value == "not applicable" || value == "na"

    gdi_mapping[value] || :skip
  end

  def process_total_applications(value)
    return "0" if value.blank? || value.downcase == "not applicable"
    value
  end

  def process_total_awards(value)
    return "0" if value.blank? || value.downcase == "not applicable"
    value
  end

  def process_intended_beneficiaries(value)
    updated_attributes["requires_additional_benefitting_countries"] = false
    return [] if value.blank? || value.to_s.downcase == "none" || value.to_s.downcase == "not applicable"

    countries = value.split("|").map { |country| country.gsub(/[[:space:]]/, " ").downcase.strip }
    return [] if countries.none?

    updated_attributes["requires_additional_benefitting_countries"] = true

    countries.map! do |country|
      return "LA" if country == "laos"
      return "LC" if country == "st lucia"

      country_to_code_mapping.fetch(country)
    rescue KeyError
      Rails.logger.warn "#{attributes} no such country '#{country}'"
      nil
    end

    countries.compact
  end

  def process_sector(value)
    mapped_sector = sector_mapping[value.to_s.downcase]

    return :skip if mapped_sector.nil?

    sector, sector_category = mapped_sector

    updated_attributes["sector_category"] = sector_category
    sector
  end

  def process_recipient_country(value)
    mapped_country = country_mapping[value.to_s.downcase]

    if mapped_country.present?
      updated_attributes["geography"] = "recipient_country"
      updated_attributes["recipient_region"] = country_to_region_mapping[mapped_country]
      return mapped_country
    end

    mapped_region = region_mapping[value.to_s.downcase]

    if mapped_region.present?
      updated_attributes["geography"] = "recipient_region"
      updated_attributes["recipient_region"] = mapped_region
      return nil
    end

    :skip
  end

  def process_planned_start_date(value)
    return :skip if value.blank? || value.downcase == "n/a" || value.downcase == "not applicable"

    Date.parse(value)
  end

  def process_planned_end_date(value)
    return :skip if value.blank? || value.downcase == "n/a" || value.downcase == "not applicable"

    Date.parse(value)
  end

  def process_actual_start_date(value)
    return :skip if value.blank? || value.downcase == "n/a" || value.downcase == "not applicable"

    Date.parse(value)
  end

  def process_actual_end_date(value)
    return :skip if value.blank? || value.downcase == "n/a" || value.downcase == "not applicable"

    Date.parse(value)
  end

  def process_flow(value)
    value = value.to_s.strip.downcase
    return :skip if value.blank? || value == "not applicable" || value == "na"

    flow_mapping[value] || :skip
  end

  def process_aid_type(value)
    value = value.to_s.strip.downcase
    return :skip if value.blank? || value == "not applicable" || value == "na"

    aid_type_mapping[value] || :skip
  end

  def process_transaction_type(value)
    value = value.to_s.strip.downcase
    return :skip if value.blank? || value == "not applicable" || value == "na"

    transaction_type_mapping[value] || :skip
  end

  def process_date(value)
    return :skip if value.blank? || value.downcase == "n/a" || value.downcase == "not applicable"

    Date.parse(value)
  end

  def process_currency(value)
    value = value.to_s.strip.downcase
    return :skip if value.blank? || value == "not applicable" || value == "na"

    default_currency_mapping[value] || :skip
  end

  def process_providing_organisation_type(value)
    value = value.to_s.strip.downcase
    return :skip if value.blank? || value == "not applicable" || value == "na"

    organisation_type_mapping[value] || :skip
  end

  private

  def programme_status_mapping
    @programme_status_mapping ||= begin
      yaml_to_objects(entity: "activity", type: "programme_status")
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
    end
  end

  def gdi_mapping
    @gdi_mapping ||= begin
      yaml_to_objects(entity: "activity", type: "gdi")
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
    end
  end

  def country_to_code_mapping
    @country_to_code_mapping ||= begin
      load_yaml(entity: "activity", type: "intended_beneficiaries")
        .values
        .flatten
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
    end
  end

  def sector_mapping
    @sector_mapping ||= begin
      load_yaml(entity: "activity", type: "sector")
        .map { |status| [status["name"].downcase, [status["code"], status["category"]]] }
        .to_h
        .merge("solar energy for centralised grids" => ["23067", "230"])
        .merge("modern biofuels manufacturing" => ["32173", "321"])
    end
  end

  def country_mapping
    @country_mapping ||= begin
      yaml_to_objects(entity: "activity", type: "recipient_country")
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
        .merge("china (people's republic of)" => "CN")
        .merge("gambia" => "GM")
        .merge("philippines" => "PH")
        .merge("tanzania" => "TZ")
        .merge("west bank and gaza strip" => "PS")
        .merge("democratic republic of the congo" => "CD")
        .merge("sudan" => "SD")
    end
  end

  def region_mapping
    @region_mapping ||= begin
      yaml_to_objects(entity: "activity", type: "recipient_region")
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
        .merge("africa, regional" => "298")
        .merge("asia, regional" => "798")
        .merge("asia" => "798")
    end
  end

  def country_to_region_mapping
    @country_to_region_mapping ||= begin
      yaml = YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/BEIS/country_to_region_mapping.yml"))
      yaml["data"].map { |status| [status["country"], status["region"]] }.to_h
    end
  end

  def flow_mapping
    @flow_mapping ||= begin
      yaml_to_objects(entity: "activity", type: "flow")
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
    end
  end

  def aid_type_mapping
    @aid_type_mapping ||= begin
      yaml_to_objects(entity: "activity", type: "aid_type")
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
    end
  end

  def transaction_type_mapping
    @transaction_type_mapping ||= begin
      yaml_to_objects(entity: "transaction", type: "transaction_type")
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
    end
  end

  def default_currency_mapping
    @default_currency_mapping ||= begin
      yaml_to_objects(entity: "generic", type: "default_currency")
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
    end
  end

  def organisation_type_mapping
    @organisation_type_mapping ||= begin
      yaml_to_objects(entity: "organisation", type: "organisation_type")
        .map { |status| [status["name"].downcase, status["code"]] }
        .to_h
    end
  end
end
