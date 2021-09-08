class BenefittingCountry
  include ActiveModel::Model
  attr_accessor :name, :recipient_code, :code, :regions

  class << self
    def all
      @all ||= Codelist.new(type: "benefitting_countries", source: "beis").map { |country| new_from_hash(country) }
    end

    def find_by_code(code)
      all.find { |country| country.code == code }
    end

    def region_from_country_codes(codes)
      codes.map { |c| find_by_code(c) }
        .map { |c| c.regions }
        .inject(:&)
        .max_by { |r| r.level.code } || Region.find_by_code(Region::DEVELOPING_COUNTRIES_CODE)
    end

    private

    def new_from_hash(country)
      new(
        name: country["name"],
        code: country["code"],
        recipient_code: country["recipient_code"],
        regions: country["regions"].map { |region|
          Region.find_by_code(region)
        }
      )
    end
  end

  class Region
    include ActiveModel::Model
    attr_accessor :name, :code, :level

    DEVELOPING_COUNTRIES_CODE = "998"

    class << self
      def all
        @all ||= Codelist.new(type: "benefitting_regions", source: "beis").map { |region| new_from_hash(region) }
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
end
