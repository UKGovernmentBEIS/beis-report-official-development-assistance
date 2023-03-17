class Activity
  class Import
    Error = Struct.new(:row_index, :attribute_name, :value, :message) {
      def csv_row
        row_index + 2
      end

      def csv_column_name
        if [:implementing_organisation_id, :implementing_org_participations].include?(attribute_name)
          return "Implementing organisation names"
        end

        if attribute_name == :oda_parent
          return "Parent ODA type"
        end

        Field.find_by_attribute_name(attribute_name: attribute_name)&.heading || attribute_name.to_s
      end
    }

    attr_reader :errors, :created, :updated

    class << self
      def invalid_non_oda_attribute_errors(activity:, converted_attributes:)
        errors = {}

        invalid_attributes = activity.programme? ? Field.invalid_for_level_b_ispf_non_oda : Field.invalid_for_level_c_d_ispf_non_oda

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

    def import(rows)
      ActiveRecord::Base.transaction do
        rows.each_with_index { |row, row_index| import_row(row, row_index) }

        if @errors.present?
          @created = []
          @updated = []
          raise ActiveRecord::Rollback
        end
      end
    end

    def import_row(row, row_index)
      action = row["RODA ID"].blank? ? create_activity(row, row_index) : update_activity(row, row_index)

      return if action.nil?

      action.errors.each do |attribute_name, (value, message)|
        add_error(row_index, attribute_name, value, message)
      end
    end

    def create_activity(row, row_index)
      if row["Parent RODA ID"].blank?
        add_error(row_index, :roda_id, row["RODA ID"], I18n.t("importer.errors.activity.cannot_create")) && return
      else
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
      end
    end

    def update_activity(row, row_index)
      if row["Parent RODA ID"].present?
        add_error(row_index, :parent_id, row["Parent RODA ID"], I18n.t("importer.errors.activity.cannot_update.parent_present")) && return
      elsif row["Partner organisation identifier"].present?
        add_error(row_index, :partner_organisation_identifier, row["Partner organisation identifier"], I18n.t("importer.errors.activity.cannot_update.partner_organisation_identifier_present")) && return
      else
        updater = Import::Updater.new(
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

    def add_error(row_index, attribute_name, value, message)
      @errors << Error.new(row_index, attribute_name, value, message)
    end
  end
end
