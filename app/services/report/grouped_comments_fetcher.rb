class Report
  class GroupedCommentsFetcher
    def initialize(report:, user:)
      @report = report
      @user = user
    end

    def all
      comments.group_by(&:activity)
    end

    private

    attr_reader :report, :user

    def comments
      if user.delivery_partner?
        report.comments.includes(
          owner: [:organisation],
          activity: [
            parent: [
              parent: [:parent],
            ],
          ]
        )
      else
        report.comments.includes(:activity)
      end
    end
  end
end
