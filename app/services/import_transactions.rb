require "date"

class ImportTransactions
  DEFAULT_CURRENCY = "GBP"
  TRANSACTION_TYPE_DISBURSEMENT = "3"

  def import(transactions)
    transactions.each { |row| import_row(row) }
  end

  def import_row(row)
    converter = Converter.new(row)
    attrs = converter.to_h
    activity = converter.activity

    assign_default_values(attrs, activity)

    CreateTransaction.new(activity: activity).call(attributes: attrs)
  end

  def assign_default_values(attrs, activity)
    organisation = activity.providing_organisation

    attrs[:currency] = DEFAULT_CURRENCY
    attrs[:transaction_type] = TRANSACTION_TYPE_DISBURSEMENT
    attrs[:providing_organisation_name] = organisation.name
    attrs[:providing_organisation_type] = organisation.organisation_type
  end

  class Converter
    FIELDS = {
      activity: "Activity RODA Identifier",
      date: "Date",
      value: "Value",
      receiving_organisation_name: "Receiving Organisation Name",
      receiving_organisation_type: "Receiving Organisation Type",
      receiving_organisation_reference: "Receiving Organisation IATI Reference",
      disbursement_channel: "Disbursement Channel",
      description: "Description",
    }

    attr_reader :activity

    def initialize(row)
      @row = row
      @attributes = convert_to_attributes
      @activity = @attributes.delete(:activity)
    end

    def to_h
      @attributes
    end

    def convert_to_attributes
      FIELDS.each_with_object({}) do |(attr_name, column_name), attrs|
        attrs[attr_name] = convert_to_attribute(attr_name, @row[column_name])
      end
    end

    def convert_to_attribute(attr_name, value)
      value = value.to_s.strip

      converter = "convert_#{attr_name}"
      value = __send__(converter, value) if respond_to?(converter)

      value
    end

    def convert_activity(id)
      Activity.find_by(roda_identifier_compound: id)
    end
  end
end
