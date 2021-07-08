class Fund
  class InvalidActivity < StandardError; end
  class InvalidFund < StandardError; end

  attr_reader :id, :name

  MAPPINGS = {
    "NF" => 1,
    "GCRF" => 2,
  }

  def initialize(id)
    data = self.class.codelist.find_item_by_code(id.to_i)

    raise InvalidFund if data.nil?

    @id = data["code"]
    @name = data["name"]
  end

  def gcrf?
    id == MAPPINGS["GCRF"]
  end

  def newton?
    id == MAPPINGS["NF"]
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

      id = MAPPINGS.fetch(activity.roda_identifier_fragment) { raise InvalidFund }

      new(id)
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
