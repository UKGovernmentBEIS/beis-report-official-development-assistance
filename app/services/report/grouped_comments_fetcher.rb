class Report
  class GroupedCommentsFetcher
    def initialize(report:, user:)
      @report = report
      @user = user
    end

    def all
      comments.group_by(&:associated_activity)
    end

    private

    attr_reader :report, :user

    def comments
      if user.partner_organisation?
        report.comments.includes(
          owner: [:organisation],
          commentable: [
            :parent_activity,
            parent: [
              parent: [:parent]
            ]
          ]
        )
      else
        report.comments.includes(commentable: [:parent_activity])
      end
    end
  end
end
