require "rails_helper"

RSpec.describe Adjustment, type: :model do
  it { should have_one(:comment) }
  it { should have_one(:creator).through(:detail).source(:user) }

  describe "#adjustment_type" do
    let(:adjustment) { build(:adjustment) }

    before do
      adjustment.adjustment_type = "Actual"
      adjustment.save
    end

    it "sets the AdjustmentDetail#adjustment_type attr on the has_one association" do
      expect(adjustment.detail.adjustment_type).to eq("Actual")
    end

    it "delegates the getter to the has_one association" do
      expect(adjustment.adjustment_type).to eq("Actual")
    end
  end

  describe "Single table inheritance from Transaction" do
    it "should inherit from the Transaction class " do
      expect(Adjustment.ancestors).to include(Transaction)
      expect(Adjustment.table_name).to eq("transactions")
      expect(Adjustment.inheritance_column).to eq("type")
    end

    it "should have the _type_ of 'Adjustment'" do
      expect(Adjustment.new.type).to eq("Adjustment")
    end

    it "should have the _transaction_type_ of '3' for 'Disbursement'" do
      expect(Adjustment.new.transaction_type).to eq("3")
    end

    it "should have the _currency_ of 'GBP'" do
      expect(Adjustment.new.currency).to eq("GBP")
    end
  end

  describe "validations" do
    let(:adjustment) do
      Adjustment.new.tap do |adjustment|
        adjustment.build_comment(body: nil)
        adjustment.build_detail(adjustment_type: "Rubbish", user: nil)
        adjustment.valid?
      end
    end

    it "validates associated comment with a helpful message" do
      expect(adjustment.errors[:comment])
        .to include("Enter a comment explaining the adjustment")
    end

    it "validates associated adjustment detail" do
      aggregate_failures do
        expect(adjustment.errors[:"detail.adjustment_type"]).to be_present
        expect(adjustment.errors[:"detail.user"]).to be_present
      end
    end
  end

  describe "associated comment" do
    let(:adjustment) { create(:adjustment) }

    context "when the comment is edited and the adjustment is saved" do
      before do
        adjustment.comment.body = "Edited comment"
        adjustment.save
      end

      it "autosaves the associated comment" do
        expect(adjustment.comment.reload.body).to eq("Edited comment")
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
