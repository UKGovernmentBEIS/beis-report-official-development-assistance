module Activities
  class ImportFromCsv
    Error = Struct.new(:row, :column, :value, :message) {
      def csv_row
        row + 2
      end
    }

    attr_reader :errors

    def initialize(organisation:)
      @organisation = organisation
      @errors = []
    end

    def import(activities)
      ActiveRecord::Base.transaction do
        activities.each_with_index { |row, index| import_row(row, index) }
        raise ActiveRecord::Rollback unless @errors.empty?
      end
    end

    def import_row(row, index)
      activity = Activity.by_roda_identifier(row["RODA ID"])

      if activity.nil?
        add_error(index, :roda_id, row["RODA ID"], I18n.t("importer.errors.activity.not_found"))
      else
        updater = ActivityUpdater.new(activity, @organisation, row)
        updater.update

        updater.errors.each do |attr_name, (value, message)|
          add_error(index, attr_name, value, message)
        end
      end
    end

    def add_error(row_number, column, value, message)
      @errors << Error.new(row_number, column, value, message)
    end

    class ActivityUpdater
      attr_reader :errors

      def initialize(activity, organisation, row)
        @activity = activity
        @organisation = organisation
        @errors = {}
        @converter = Converter.new(row)
        @errors.update(@converter.errors)
      end

      def update
        return unless @activity && @errors.empty?

        attributes = @converter.to_h

        return if @activity.update(attributes)

        @activity.errors.each do |attr_name, message|
          @errors[attr_name] ||= [@converter.raw(attr_name), message]
        end
      end
    end

    class Converter
      include CodelistHelper

      attr_reader :errors

      FIELDS = {
        title: "Title",
        description: "Description",
        recipient_region: "Recipient Region",
      }

      def initialize(row)
        @row = row
        @errors = {}
        @attributes = convert_to_attributes
      end

      def raw(attr_name)
        @row[FIELDS[attr_name]]
      end

      def to_h
        @attributes
      end

      def convert_to_attributes
        FIELDS.each_with_object({}) do |(attr_name, column_name), attrs|
          attrs[attr_name] = convert_to_attribute(attr_name, @row[column_name]) if @row[column_name].present?
        end
      end

      def convert_to_attribute(attr_name, value)
        original_value = value.clone
        value = value.to_s.strip

        converter = "convert_#{attr_name}"
        value = __send__(converter, value) if respond_to?(converter)

        value
      rescue => error
        @errors[attr_name] = [original_value, error.message]
        nil
      end

      def convert_recipient_region(region)
        validate_from_codelist(
          region,
          :recipient_region,
          I18n.t("importer.errors.activity.invalid_region"),
        )
      end

      def validate_from_codelist(code, entity, message)
        return nil if code.blank?

        codelist = load_yaml(entity: :activity, type: entity)
        valid_codes = codelist.map { |entry| entry.fetch("code") }

        raise message unless valid_codes.include?(code)

        code
      end
    end
  end
end
