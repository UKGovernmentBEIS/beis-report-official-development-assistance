class Transaction
  class GroupedActualsFetcher
    def initialize(report)
      @report = report
    end

    def call
      report.actuals
        .joins(:parent_activity)
        .includes([:parent_activity, :comment])
        .where("activities.id": report.reportable_activities.pluck(:id))
        .map { |actual| TransactionPresenter.new(actual) }
        .group_by { |actual| ActivityPresenter.new(actual.parent_activity) }
    end

    private

    attr_reader :report
  end
end
