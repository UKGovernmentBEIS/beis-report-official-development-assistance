class Activity
  class Import
    Error = Struct.new(:row, :column, :value, :message) {
      def csv_row
        row + 2
      end

      def csv_column
        ACTIVITY_CSV_COLUMNS.dig(column, :heading) || column.to_s
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
        activities.each_with_index { |row, index| import_row(row, index) }

        if errors.present?
          @created = []
          @updated = []
          raise ActiveRecord::Rollback
        end
      end
    end

    private

    def import_row(row, index)
      action = row["RODA ID"].blank? ? create_activity(row, index) : update_activity(row, index)

      return if action.nil?

      action.errors.each do |attr_name, (value, message)|
        add_error(index, attr_name, value, message)
      end
    end

    def create_activity(row, index)
      if row["Parent RODA ID"].present?
        creator = Creator.new(
          row: row,
          uploader: @uploader,
          partner_organisation: @partner_organisation,
          report: @report,
          is_oda: @is_oda
        )
        creator.create
        created << creator.activity unless creator.errors.any?

        creator
      else
        add_error(index, :roda_id, row["RODA ID"], I18n.t("importer.errors.activity.cannot_create")) && return
      end
    end

    def update_activity(row, index)
      if row["Parent RODA ID"].present?
        add_error(index, :parent_id, row["Parent RODA ID"], I18n.t("importer.errors.activity.cannot_update.parent_present")) && return
      elsif row["Partner Organisation Identifier"].present?
        add_error(index, :partner_organisation_identifier, row["Partner Organisation Identifier"], I18n.t("importer.errors.activity.cannot_update.partner_organisation_identifier_present")) && return
      else
        updater = Updater.new(
          row: row,
          uploader: @uploader,
          partner_organisation: @partner_organisation,
          report: @report,
          is_oda: @is_oda
        )
        updater.update
        updated << updater.activity unless updater.errors.any?

        updater
      end
    end

    def add_error(row_number, column, value, message)
      @errors << Error.new(row_number, column, value, message)
    end
  end
end
