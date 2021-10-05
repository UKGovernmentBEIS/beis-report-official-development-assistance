class Report
  class GroupedCommentsFetcher
    def initialize(report:, user:)
      @report = report
      @user = user
    end

    def all
      comments.group_by(&:commentable)
    end

    private

    attr_reader :report, :user

    def comments
      if user.delivery_partner?
        report.comments.includes(
          owner: [:organisation],
          commentable: [
            parent: [
              parent: [:parent],
            ],
          ]
        )
      else
        report.comments.includes(:commentable)
      end
    end
  end
end
