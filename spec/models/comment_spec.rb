require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "associations" do
    it { should belong_to(:commentable) }
    it { should belong_to(:owner).class_name("User").optional(true) }
    it { should belong_to(:report).optional(true) }
  end

  describe "validations" do
    it { should validate_presence_of(:comment) }
  end

  it { should validate_presence_of(:comment) }

  it "should set the commentable type before creating the comment" do
    adjustment = create(:adjustment)
    adjustment_comment = create(:comment, commentable: adjustment)

    refund = create(:refund)
    refund_comment = create(:comment, commentable: refund)

    expect(adjustment_comment.commentable_type).to eq("Adjustment")
    expect(refund_comment.commentable_type).to eq("Refund")
  end
end
