require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "associations" do
    it { should belong_to(:commentable) }
    it { should belong_to(:owner).class_name("User").optional(true) }
    it { should belong_to(:report) }
  end

  describe "validations" do
    it { should validate_presence_of(:body) }
  end

  it { should validate_presence_of(:body) }

  it "should set the commentable type before creating the comment" do
    adjustment = create(:adjustment)
    adjustment_comment = create(:comment, commentable: adjustment)

    refund = create(:refund)
    refund_comment = create(:comment, commentable: refund)

    expect(adjustment_comment.commentable_type).to eq("Adjustment")
    expect(refund_comment.commentable_type).to eq("Refund")
  end

  describe "#associated_activity" do
    subject { comment.associated_activity }

    context "when the commentable type is Activity" do
      let(:comment) { build(:comment, :with_activity) }

      it { is_expected.to eq(comment.commentable) }
    end

    context "when the commentable type is Refund" do
      let(:comment) { build(:comment, :with_refund) }

      it { is_expected.to eq(comment.commentable.parent_activity) }
    end

    context "when the commentable type is Adjustment" do
      let(:comment) { build(:comment, :with_adjustment) }

      it { is_expected.to eq(comment.commentable.parent_activity) }
    end
  end

  describe ".for_activity" do
    it "fetches comments related to a given activity" do
      activity = create(:project_activity)
      refund = create(:refund, parent_activity: activity)
      adjustment = create(:adjustment, parent_activity: activity)

      activity_comment = create(:comment, commentable: activity)

      _comments = create_list(:comment, 5)
      _refunds = create_list(:refund, 2)
      _adjustments = create_list(:adjustment, 2)

      expect(Comment.for_activity(activity)).to match_array([
        activity_comment,
        refund.comment,
        adjustment.comment
      ])
    end
  end
end
