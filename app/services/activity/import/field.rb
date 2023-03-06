class Activity::Import::Field
  class << self
    def all
      from_source(source)
    end

    def find_by_attribute_name(attribute_name:)
      field = source[attribute_name]
      return nil if field.nil?

      from_source({attribute_name => field}).first
    end

    def where_headings(headings:)
      fields = source.select { |_key, value| headings.include?(value[:heading]) }

      from_source(fields)
    end

    def where_level_and_type(level:, type:)
      fields = source.select { |_key, value| value.dig(:inclusion, level, type) }

      from_source(fields)
    end

    def invalid_for_level_b_ispf_non_oda
      level_b_non_oda_attributes = []
      level_b_oda_attributes = []

      source.each do |attribute, column|
        level_b_non_oda_attributes << attribute if column.dig(:inclusion, :level_b, :ispf_non_oda)
        level_b_oda_attributes << attribute if column.dig(:inclusion, :level_b, :ispf_oda)
      end

      level_b_oda_attributes - level_b_non_oda_attributes
    end

    def invalid_for_level_c_d_ispf_non_oda
      level_c_d_non_oda_attributes = []
      level_c_d_oda_attributes = []

      source.each do |attribute, column|
        level_c_d_non_oda_attributes << attribute if column.dig(:inclusion, :level_c_d, :ispf_non_oda)
        level_c_d_oda_attributes << attribute if column.dig(:inclusion, :level_c_d, :ispf_oda)
      end

      level_c_d_oda_attributes - level_c_d_non_oda_attributes
    end

    private

    def from_source(fields)
      fields.map do |key, value|
        new(
          attribute_name: key.to_sym,
          heading: value[:heading],
          exclude_from_converter: value[:exclude_from_converter]
        )
      end
    end

    def source
      ACTIVITY_CSV_COLUMNS
    end
  end

  attr_reader :attribute_name, :heading, :exclude_from_converter

  def initialize(attribute_name:, heading:, exclude_from_converter:)
    @attribute_name = attribute_name
    @heading = heading
    @exclude_from_converter = exclude_from_converter
  end
end
