class MatchedEffort < ApplicationRecord
  belongs_to :organisation
  belongs_to :activity

  FUNDING_TYPE_CODES = Codelist.new(type: "matched_effort_funding_type", source: "beis")
  CATEGORY_CODES = Codelist.new(type: "matched_effort_category", source: "beis")

  enum funding_type: FUNDING_TYPE_CODES.hash_of_coded_names
  enum category: CATEGORY_CODES.hash_of_coded_names

  validates_presence_of :organisation_id, :funding_type
  validates_presence_of :category, if: -> { in_kind? || reciprocal? }

  validates_with MatchedEffortOrganisationValidator, if: -> { organisation_id.present? }
  validates_with MatchedEffortCategoryValidator

  FundingType = Struct.new(:code, :name) {
    class << self
      def all
        FUNDING_TYPE_CODES.map { |type|
          new(type["code"], type["name"])
        }
      end

      def by_coded_name(coded_name)
        all.find { |type| type.coded_name == coded_name }
      end
    end

    def coded_name
      MatchedEffort.funding_types.invert[code]
    end

    def categories
      Category.all.select { |category| category.funding_type == code }
    end
  }

  Category = Struct.new(:code, :name, :funding_type) {
    class << self
      def all
        CATEGORY_CODES.map { |category|
          new(category["code"], category["name"], category["funding_type"])
        }
      end

      def by_coded_name(coded_name)
        all.find { |type| type.coded_name == coded_name }
      end
    end

    def coded_name
      MatchedEffort.categories.invert[code]
    end
  }
end
