class SpendingBreakdownJob < ApplicationJob
  def perform(requester_id:, fund_id:)
    requester = User.find(requester_id)
    fund = Fund.new(fund_id)

    export = Export::SpendingBreakdown.new(source_fund: fund)
  end
end
