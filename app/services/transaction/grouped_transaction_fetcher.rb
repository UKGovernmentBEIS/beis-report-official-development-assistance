class Transaction
  class GroupedTransactionFetcher
    def initialize(report)
      @report = report
    end

    def call
      report.transactions
        .includes([:parent_activity])
        .map { |transaction| TransactionPresenter.new(transaction) }
        .group_by { |transaction| ActivityPresenter.new(transaction.parent_activity) }
    end

    private

    attr_reader :report
  end
end
