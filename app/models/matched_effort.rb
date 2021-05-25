class MatchedEffort < ApplicationRecord
  belongs_to :organisation
  belongs_to :activity

  enum funding_type: Codelist.new(type: "matched_effort_funding_type", source: "beis").hash_of_coded_names
  enum category: Codelist.new(type: "matched_effort_category", source: "beis").hash_of_coded_names

  validates_presence_of :organisation_id, :funding_type, :category, :committed_amount, :currency, :exchange_rate, :date_of_exchange_rate

  validates_with MatchedEffortOrganisationValidator, if: -> { organisation_id.present? }
end
