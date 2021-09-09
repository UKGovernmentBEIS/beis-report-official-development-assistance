require "rails_helper"

RSpec.describe Refund, type: :model do
  let(:refund) { build(:refund) }
  it { should have_one(:comment) }

  it { should belong_to(:parent_activity) }
  it { should belong_to(:report) }

  it { should validate_presence_of(:financial_quarter) }
  it { should validate_presence_of(:financial_year) }
  it { should validate_presence_of(:value) }
  describe "validations" do
    let(:refund) do
      Refund.new.tap do |refund|
        refund.build_comment(comment: nil)
        refund.valid?
      end
    end

    it "validates associated comment with a helpful message" do
      expect(refund.errors[:comment])
        .to include("Enter a comment describing the need for the refund")
    end
  end

  describe "associated comment" do
    let(:refund) { create(:refund) }

    context "when the comment is edited and the refund is saved" do
      before do
        refund.comment.comment = "Edited comment"
        refund.save
      end

      it "autosaves the associated comment" do
        expect(refund.comment.reload.comment).to eq("Edited comment")
      end
    end
  end
end
