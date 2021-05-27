class ExternalIncome < ApplicationRecord
  include PublicActivity::Common
  include HasFinancialQuarter

  belongs_to :organisation
  belongs_to :activity
end
