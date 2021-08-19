class Refund
  class GroupedRefundFetcher
    def initialize(report)
      @report = report
    end

    def call
      report.refunds
        .includes([:parent_activity])
        .map { |refund| RefundPresenter.new(refund) }
        .group_by { |refund| ActivityPresenter.new(refund.parent_activity) }
    end

    private

    attr_reader :report
  end
end
