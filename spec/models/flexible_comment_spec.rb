require "rails_helper"

RSpec.describe FlexibleComment do
  subject { build(:flexible_comment) }

  it { should belong_to(:commentable) }
  it { should belong_to(:owner).class_name("User").optional(true) }
  it { should belong_to(:report).optional(true) }
  it { should validate_presence_of(:comment) }

  it "should set the commentable type before creating the comment" do
    adjustment = create(:adjustment)
    adjustment_comment = create(:flexible_comment, commentable: adjustment)

    refund = create(:refund)
    refund_comment = create(:flexible_comment, commentable: refund)

    expect(adjustment_comment.commentable_type).to eq("Adjustment")
    expect(refund_comment.commentable_type).to eq("Refund")
  end
end
