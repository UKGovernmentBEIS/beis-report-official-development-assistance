class Budget
  class Import
    Error = Struct.new(:row, :column, :value, :message) {
      def csv_row
        row + 2
      end

      def csv_column
        Converter::FIELDS[column] || column.to_s
      end
    }

    attr_reader :errors, :created

    def initialize(uploader:)
      @uploader = uploader
      @uploader_organisation = uploader.organisation
      @errors = []
      @created = []
    end

    def import(budgets)
      ActiveRecord::Base.transaction do
        budgets.each_with_index { |row, index| import_row(row, index) }

        if @errors.present?
          @created = []
          raise ActiveRecord::Rollback
        end
      end
    end

    def import_row(row, index)
      action = create_budget(row, index)

      return if action.nil?

      action.errors.each do |attr_name, (value, message)|
        add_error(index, attr_name, value, message)
      end
    end

    def create_budget(row, index)
      if row["Activity RODA ID"].present?
        creator = BudgetCreator.new(row: row, uploader: @uploader)
        creator.create
        created << creator.budget unless creator.errors.any?

        creator
      else
        add_error(index, :parent_activity_id, row["Activity RODA ID"], I18n.t("importer.errors.budget.cannot_create")) && return
      end
    end

    def add_error(row_number, column, value, message)
      @errors << Error.new(row_number, column, value, message)
    end

    class BudgetCreator
      attr_reader :errors, :row, :budget

      def initialize(row:, uploader:)
        @row = row
        @uploader = uploader
        @errors = {}
        @parent_activity = fetch_parent(@row["Activity RODA ID"])
        @converter = Converter.new(row, @parent_activity)

        @errors.update(@converter.errors)
      end

      def create
        return unless @errors.blank?

        result = CreateBudget.new(activity: @parent_activity).call(attributes: @converter.to_h)
        @budget = result.object

        return true if @budget.save

        @budget.errors.each do |error|
          @errors[error.attribute] ||= [@converter.raw(error.attribute), error.message]
        end
      end

      private

      def fetch_parent(roda_id)
        Activity.by_roda_identifier(roda_id)
      end
    end

    class Converter
      attr_reader :errors

      FIELDS = {
        budget_type: "Type",
        financial_year: "Financial year",
        value: "Budget amount",
        providing_organisation_name: "Providing organisation",
        providing_organisation_type: "Providing organisation type",
        providing_organisation_reference: "IATI reference",
        parent_activity_id: "Activity RODA ID"
      }

      ALLOWED_BLANK_FIELDS = ["IATI reference"]

      DIRECT_ALLOWED_BLANK_FIELDS = [
        *ALLOWED_BLANK_FIELDS,
        "Providing organisation",
        "Providing organisation type"
      ]

      def initialize(row, parent_activity)
        @row = row
        @parent_activity = parent_activity
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
        FIELDS.each_with_object({}) { |(attr_name, column_name), attrs|
          attrs[attr_name] = convert_to_attribute(attr_name, @row[column_name]) if field_should_be_converted?(column_name)
        }
      end

      def field_should_be_converted?(column_name)
        !field_can_be_blank?(column_name) || @row[column_name].present?
      end

      def field_can_be_blank?(column_name)
        type_is_direct = @row["Type"] == Budget.budget_types["direct"].to_s
        allowed_blank_fields = type_is_direct ? DIRECT_ALLOWED_BLANK_FIELDS : ALLOWED_BLANK_FIELDS

        allowed_blank_fields.include?(column_name)
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

      def convert_budget_type(budget_type)
        valid_budget_types = Budget.budget_types.values.map(&:to_s)
        raise I18n.t("importer.errors.budget.invalid_budget_type") unless valid_budget_types.include?(budget_type)

        budget_type.to_i
      end

      def convert_financial_year(financial_year)
        financial_year.strip!
        start_year = financial_year[0, 4].to_i
        end_year = financial_year[5, 9].to_i

        raise I18n.t("importer.errors.budget.invalid_financial_year") if end_year != start_year + 1

        start_year
      end

      def convert_parent_activity_id(_parent_activity_id)
        raise I18n.t("importer.errors.budget.parent_not_found") if @parent_activity.nil?

        @parent_activity.id
      end

      def convert_providing_organisation_name(providing_organisation_name)
        raise I18n.t("importer.errors.budget.invalid_providing_organisation_name") if providing_organisation_name.blank?

        providing_organisation_name
      end

      def convert_providing_organisation_type(providing_organisation_type)
        organisation_types = ApplicationController.helpers.organisation_type_options
        organisation_type_codes = []

        organisation_types.each do |organisation_type|
          organisation_type_codes << organisation_type.code if organisation_type.code.present?
        end

        raise I18n.t("importer.errors.budget.invalid_providing_organisation_type") unless organisation_type_codes.include?(providing_organisation_type)

        providing_organisation_type
      end

      def convert_value(value)
        raise I18n.t("importer.errors.budget.invalid_value") unless value.present? && value.to_d != "0".to_d && value.to_d <= "99_999_999_999.00".to_d

        value
      end
    end
  end
end
