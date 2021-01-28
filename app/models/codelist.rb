class Codelist
  class UnreadableCodelist < StandardError; end
  class UnrecognisedSource < StandardError; end
  class KeyNotFound < StandardError; end

  include Enumerable

  attr_reader :type, :source, :list

  def initialize(type:, source: "iati")
    raise UnrecognisedSource unless source.in?(%w[iati beis])

    @type = type
    @source = source
    @list = fetch_codelist
  end

  class << self
    def codelists
      if Rails.env.production?
        @codelists ||= initialize_codelists
      else
        initialize_codelists
      end
    end

    def codelist_to_hash(path)
      Dir.glob("#{Rails.root}/vendor/data/codelists/#{path}/**/*.yml").map { |filename|
        [File.basename(filename).split(".").first, YAML.safe_load(File.read(filename))]
      }.to_h
    end

    def initialize_codelists
      {
        "iati" => codelist_to_hash("IATI/#{IATI_VERSION}"),
        "beis" => codelist_to_hash("BEIS"),
      }
    end
  end

  def to_objects(with_empty_item: true)
    objects = list.collect { |item|
      next if item["status"] == "withdrawn"
      OpenStruct.new(name: item["name"], code: item["code"])
    }.compact.sort_by(&:name)

    if with_empty_item
      empty_item = OpenStruct.new(name: "", code: "")
      objects.unshift(empty_item)
    end
    objects
  end

  def to_objects_with_description(code_displayed_in_name: false, entity: "activity", type: "")
    data = list.collect { |item|
      name = code_displayed_in_name ? "#{item["name"]} (#{item["code"]})" : item["name"]
      description = I18n.t("form.hint.activity.options.#{type}.#{item["code"]}", default: item["description"])

      OpenStruct.new(name: name, code: item["code"], description: description)
    }

    data.sort_by(&:code)
  end

  def to_objects_with_categories(include_withdrawn: false)
    return [] if list.empty?

    list.collect { |item|
      next if item["status"] == "withdrawn" && include_withdrawn == false
      OpenStruct.new(name: item["name"], code: item["code"], category: item["category"])
    }.compact.sort_by(&:name)
  end

  def each
    list.map { |item| yield item }
  end

  def empty?
    list.count == 0
  end

  def values
    list.values
  end

  def values_for(key)
    values = list.pluck(key).compact

    raise KeyNotFound if values.empty?

    values
  end

  private def fetch_codelist
    codelist = self.class.codelists[source][type]

    raise UnreadableCodelist if codelist.blank?

    codelist["data"]
  end
end
