class Fund
  class InvalidActivity < StandardError; end

  class InvalidFund < StandardError; end

  attr_reader :id, :name, :short_name

  def initialize(id)
    codelist_data = self.class.codelist.find_item_by_code(id.to_i)

    raise InvalidFund if codelist_data.nil?

    @id = codelist_data["code"]
    @name = codelist_data["name"]
    @short_name = codelist_data["short_name"]
  end

  def gcrf?
    short_name == "GCRF"
  end

  def newton?
    short_name == "NF"
  end

  def activity
    Activity.fund.find_by!(source_fund_code: id)
  end

  def ==(other)
    self.class == other.class && id == other.id
  end

  class << self
    def from_activity(activity)
      raise InvalidActivity unless activity.fund?

      by_short_name(activity.roda_identifier)
    end

    def by_short_name(short_name)
      all.find(-> { raise InvalidFund }) { |fund|
        fund.short_name == short_name
      }
    end

    def all
      valid_codes.map { |code| new(code) }
    end

    def codelist
      Codelist.new(type: "fund_types", source: "beis")
    end

    private

    def valid_codes
      codelist.values_for("code")
    end
  end
end
