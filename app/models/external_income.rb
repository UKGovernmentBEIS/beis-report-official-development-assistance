class ExternalIncome < ApplicationRecord
  include PublicActivity::Common

  belongs_to :organisation
  belongs_to :activity
end
