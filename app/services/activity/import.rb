class Activity
  class Import
    Error = Struct.new(:row_index, :attribute, :value, :message) {
      def csv_row
        row_index + 2
      end

      def csv_column
        ACTIVITY_CSV_COLUMNS.dig(attribute, :heading) || attribute.to_s
      end
    }

    attr_reader :errors, :created, :updated

    class << self
      def filtered_csv_column_headings(level:, type:)
        headings = []

        ACTIVITY_CSV_COLUMNS.each do |attribute, column|
          headings << column[:heading] if column.dig(:inclusion, level, type)
        end

        headings
      end

      def invalid_non_oda_attribute_errors(activity:, converted_attributes:)
        errors = {}

        invalid_attributes = activity.programme? ?
          INVALID_LEVEL_B_ISPF_NON_ODA_ATTRIBUTES : INVALID_LEVEL_C_D_ISPF_NON_ODA_ATTRIBUTES

        invalid_attributes.each do |invalid_attribute|
          value = converted_attributes[invalid_attribute]

          errors[invalid_attribute] = [value, I18n.t("importer.errors.activity.oda_attribute_in_non_oda_activity")] if value.present?
        end

        errors
      end

      def is_oda_by_type(type:)
        {
          ispf_oda: true,
          ispf_non_oda: false,
          non_ispf: nil
        }[type]
      end
    end

    def initialize(uploader:, partner_organisation:, report:, is_oda:)
      @uploader = uploader
      @uploader_organisation = uploader.organisation
      @partner_organisation = partner_organisation
      @report = report
      @is_oda = is_oda
      @errors = []
      @created = []
      @updated = []
    end

    def import(activities)
      ActiveRecord::Base.transaction do
        activities.each_with_index { |row, row_index| import_row(row, row_index) }

        if errors.present?
          @created = []
          @updated = []
          raise ActiveRecord::Rollback
        end
      end
    end

    private

    def import_row(row, row_index)
      action_type = row["RODA ID"].blank? ? :create : :update

      return unless validate_presence_before_action(row, row_index, action_type)

      action_config = {
        create: {klass: Creator, call: :create, collection: created},
        update: {klass: Updater, call: :update, collection: updated}
      }[action_type]

      actioner = action_config[:klass].new(
        row: row,
        uploader: @uploader,
        partner_organisation: @partner_organisation,
        report: @report,
        is_oda: @is_oda
      )

      actioner.send(action_config[:call])

      actioner.errors.each do |attribute, (value, message)|
        add_error(row_index, attribute, value, message)
      end

      action_config[:collection] << actioner.activity unless errors.present?
    end

    def validate_presence_before_action(row, row_index, action_type)
      pre_action_presence_validators[action_type].all? do |validator|
        value = row[validator.dig(:check, :heading)]

        unless value.present? == validator.dig(:check, :present)
          add_error(
            row_index,
            validator.dig(:error, :attribute),
            value,
            validator.dig(:error, :message)
          )

          return false
        end

        true
      end
    end

    def pre_action_presence_validators
      error_messages = I18n.t("importer.errors.activity")

      {
        create: [
          {
            check: {heading: "Parent RODA ID", present: true},
            error: {attribute: :roda_id, message: error_messages[:cannot_create]}
          }
        ],
        update: [
          {
            check: {heading: "Parent RODA ID", present: false},
            error: {attribute: :parent_id, message: error_messages.dig(:cannot_update, :parent_present)}
          },
          {
            check: {heading: "Partner organisation identifier", present: false},
            error: {
              attribute: :partner_organisation_identifier,
              message: error_messages.dig(:cannot_update, :partner_organisation_identifier_present)
            }
          }
        ]
      }
    end

    def add_error(row_number, attribute, value, message)
      @errors << Error.new(row_number, attribute, value, message)
    end
  end
end
