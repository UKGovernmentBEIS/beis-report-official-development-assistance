require "nokogiri"

module IATIValidator
  class XML
    attr_reader :errors
    class InvalidError < StandardError
      def initialize(errors, url)
        @errors = errors
        @url = url
      end

      def skip_validation_url
        url = Addressable::URI.parse(@url)
        query = url.query_values || {}
        url.query_values = query.merge(skip_validation: 1)
        url
      end

      def to_s
        "XML validation errors were found in #{skip_validation_url}\n#{@errors.join("\n")}"
      end
    end

    SCHEMAS = {"iati-activities" => "iati-activities",
               "iati-organisations" => "iati-organisations",
               "registry-record" => "iati-registry-record"}
    PATH = "vendor/data/IATI-Schemas-2.03/%s-schema.xsd"

    def initialize(content)
      @content = content
      @errors = []
    end

    def error(message)
      @errors << message
      false
    end

    def valid?
      doc = Nokogiri::XML(@content)

      return error("Not XML. #{doc.errors}") unless doc.errors.empty?
      return error("No root node.") unless doc.root

      schema = SCHEMAS[doc.root.name]
      return error("Did not recognise opening tag #{doc.root.name}") unless schema

      xsd = Nokogiri::XML::Schema(File.open(PATH % schema))

      validation_errors = xsd.validate(doc)
      return true if validation_errors.empty?

      validation_errors.each do |validation_error|
        error(validation_error.message)
      end
      false
    end
  end
end
