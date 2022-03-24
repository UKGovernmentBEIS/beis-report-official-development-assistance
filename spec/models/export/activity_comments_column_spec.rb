RSpec.describe Export::ActivityCommentsColumn do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @report = create(:report)

    create_activity_with_comments
    create_activity_with_multiple_comments_in_report
    create_activity_with_no_comments

    @activities = create_list(:project_activity, 2)

    @activities << @activity_with_comments
    @activities << @activity_with_multiple_comments_in_report
    @activities << @activity_with_no_comments
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "when there are activities" do
    subject { described_class.new(activities: @activities, report: @report) }

    describe "#headers" do
      it "returns the headers" do
        expect(subject.headers).to eq ["Comments in report"]
      end
    end

    describe "#rows" do
      context "when the activity has no comments" do
        it "returns an empty string" do
          expect(subject.rows.fetch(@activity_with_no_comments.id)).to eql ""
        end
      end

      context "when the activity has a single comment in the report" do
        it "returns the body of the comment" do
          expect(subject.rows.fetch(@activity_with_comments.id)).to eql @comment_in_report.body
        end
      end

      context "when the activity has multiple comments" do
        it "returns the body of each comment separated by `----`" do
          value_for_activity = subject.rows.fetch(@activity_with_multiple_comments_in_report.id)

          expect(value_for_activity).to include "----"
          expect(value_for_activity).to include(@refund_comment.body)
          expect(value_for_activity).to include(@adjustment_comment.body)
        end
      end

      it "returns the correct number of rows" do
        expect(subject.rows.count).to eq 5
      end
    end
  end

  context "when there are no activities" do
    subject { described_class.new(activities: [], report: @report) }

    describe "#headers" do
      it "returns the headers" do
        expect(subject.headers).to eq ["Comments in report"]
      end
    end

    describe "#rows" do
      it "returns an empty array" do
        expect(subject.rows).to eq []
      end
    end
  end

  def create_activity_with_comments
    @activity_with_comments = create(:project_activity)
    @comment_in_report = create(:comment, commentable: @activity_with_comments, commentable_type: "Activity", report: @report)
  end

  def create_activity_with_multiple_comments_in_report
    @activity_with_multiple_comments_in_report = create(:project_activity)
    refund = create(:refund, parent_activity: @activity_with_multiple_comments_in_report)
    @refund_comment = create(:comment, commentable: refund, commentable_type: "Refund", report: @report)
    adjustment = create(:adjustment, parent_activity: @activity_with_multiple_comments_in_report)
    @adjustment_comment = create(:comment, commentable: adjustment, commentable_type: "Adjustment", report: @report)
  end

  def create_activity_with_no_comments
    @activity_with_no_comments = create(:project_activity)
  end
end
