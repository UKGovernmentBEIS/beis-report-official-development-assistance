class BenefittingRegion
  include ActiveModel::Model
  attr_accessor :name, :code, :level

  DEVELOPING_COUNTRIES_CODE = "998"

  class << self
    def all
      @all ||= Codelist.new(type: "benefitting_regions", source: "beis").map { |region| new_from_hash(region) }
    end

    def all_for_level_code(level_code = 3)
      level = BenefittingRegion::Level.find_by_code(level_code)
      all.select { |region| region.level == level }
    end

    def find_by_code(code)
      all.find { |region| region.code == code }
    end

    private

    def new_from_hash(region)
      new(
        name: region["name"],
        code: region["code"],
        level: Level.find_by_code(region["level"]),
      )
    end
  end

  def hash
    code.hash
  end

  def eql?(other)
    code == other.code
  end

  def ==(other)
    code == other.code
  end

  class Level
    include ActiveModel::Model
    attr_accessor :name, :code

    class << self
      def all
        @all ||= Codelist.new(type: "benefitting_region_levels", source: "beis").map { |level| new_from_hash(level) }
      end

      def find_by_code(code)
        all.find { |level| level.code == code }
      end

      private

      def new_from_hash(level)
        new(name: level["name"], code: level["code"])
      end
    end
  end
end
