class ExternalIncome < ApplicationRecord
  include HasFinancialQuarter

  belongs_to :organisation
  belongs_to :activity

  validates_presence_of :organisation_id, :financial_quarter, :financial_year, :amount
end
