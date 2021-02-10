class Fund
  attr_reader :code

  class InvalidActivity < StandardError; end
  class InvalidFund < StandardError; end

  MAPPINGS = {
    "NF" => 1,
    "GCRF" => 2,
  }

  def initialize(id)
    @code = self.class.codelist.find { |c| c["code"] == id }

    raise InvalidFund if @code.nil?
  end

  def id
    code["code"]
  end

  def name
    code["name"]
  end

  def gcrf?
    id == MAPPINGS["GCRF"]
  end

  def newton?
    id == MAPPINGS["NF"]
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
