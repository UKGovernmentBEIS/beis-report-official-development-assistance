class Transaction
  class GroupedActualsFetcher
    def initialize(report)
      @report = report
    end

    def call
      report.actuals
        .includes([:parent_activity])
        .map { |actual| TransactionPresenter.new(actual) }
        .group_by { |actual| ActivityPresenter.new(actual.parent_activity) }
    end

    private

    attr_reader :report
  end
end
