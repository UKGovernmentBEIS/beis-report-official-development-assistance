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

    # Set call_present if call_open_date or call_close_date provided
    updated_attributes["call_present"] = updated_attributes["call_open_date"].present? || updated_attributes["call_close_date"].present?

    # Return the processed set of attributes
    updated_attributes
  end

  def process_call_open_date(value)
    return :skip if value.blank? || value == "N/A"
    Date.parse(value)
  end

  def process_call_close_date(value)
    return :skip if value.blank? || value == "N/A"
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
    return nil if value == "not applicable"

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
    return [] if value.blank?

    countries = value.split("|").map { |country| country.gsub(/[[:space:]]/, " ").downcase.strip }
    return [] if countries.none?

    updated_attributes["requires_additional_benefitting_countries"] = true

    countries.map! do |country|
      country_to_code_mapping.fetch(country)
    rescue KeyError
      Rails.logger.warn "#{attributes} no such country '#{country}'"
      nil
    end

    countries.compact
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
end
