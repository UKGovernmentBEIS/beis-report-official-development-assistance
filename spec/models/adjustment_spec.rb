require "rails_helper"

RSpec.describe Adjustment, type: :model do
  it { should have_one(:comment) }

  describe "Single table inheritance from Transaction" do
    it "should inherit from the Transaction class " do
      expect(Adjustment.ancestors).to include(Transaction)
      expect(Adjustment.table_name).to eq("transactions")
      expect(Adjustment.inheritance_column).to eq("type")
    end

    it "should have the _type_ of 'Adjustment'" do
      expect(Adjustment.new.type).to eq("Adjustment")
    end
  end

  describe "validations" do
    let(:adjustment) do
      Adjustment.new.tap do |adjustment|
        adjustment.build_comment(comment: nil)
        adjustment.valid?
      end
    end

    it "validates associated comment with a helpful message" do
      expect(adjustment.errors[:comment])
        .to include("Enter a comment explaining the adjustment")
    end
  end

  describe "associated comment" do
    let(:adjustment) { create(:adjustment) }

    context "when the comment is edited and the adjustment is saved" do
      before do
        adjustment.comment.comment = "Edited comment"
        adjustment.save
      end

      it "autosaves the associated comment" do
        expect(adjustment.comment.reload.comment).to eq("Edited comment")
      end
    end
  end

  describe "#value" do
    let(:negative) { BigDecimal("-100.01") }
    let(:positive) { BigDecimal("100.01") }

    context "when a negative value is given" do
      let(:negative_adjustment) { create(:adjustment, value: negative) }

      it "persists a negative" do
        expect(negative_adjustment.value).to eq(negative)
      end
    end

    context "when a positive value is given" do
      let(:positive_adjustment) { create(:adjustment, value: positive) }

      it "persists a positive" do
        expect(positive_adjustment.value).to eq(positive)
      end
    end
  end
end
