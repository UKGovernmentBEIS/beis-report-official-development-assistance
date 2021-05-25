class MatchedEffort < ApplicationRecord
  belongs_to :organisation
  belongs_to :activity

  enum funding_type: Codelist.new(type: "matched_effort_funding_type", source: "beis").hash_of_coded_names
  enum category: Codelist.new(type: "matched_effort_category", source: "beis").hash_of_coded_names
end
