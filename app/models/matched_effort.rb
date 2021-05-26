class MatchedEffort < ApplicationRecord
  belongs_to :organisation
  belongs_to :activity

  FUNDING_TYPE_CODES = Codelist.new(type: "matched_effort_funding_type", source: "beis")
  CATEGORY_CODES = Codelist.new(type: "matched_effort_category", source: "beis")

  enum funding_type: FUNDING_TYPE_CODES.hash_of_coded_names
  enum category: CATEGORY_CODES.hash_of_coded_names

  validates_presence_of :organisation_id, :funding_type, :committed_amount, :currency, :exchange_rate, :date_of_exchange_rate
  validates_presence_of :category, if: -> { in_kind? || reciprocal? }

  validates_with MatchedEffortOrganisationValidator, if: -> { organisation_id.present? }
  validates_with MatchedEffortCategoryValidator
end
