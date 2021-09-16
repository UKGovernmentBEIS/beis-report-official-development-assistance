require "rails_helper"

RSpec.describe Refund, type: :model do
  it { should have_one(:comment) }

  describe "Single table inheritance from Transaction" do
    it "should inherit from the Transaction class " do
      expect(Refund.ancestors).to include(Transaction)
      expect(Refund.table_name).to eq("transactions")
      expect(Refund.inheritance_column).to eq("type")
    end

    it "should have the _type_ of 'Refund'" do
      expect(Refund.new.type).to eq("Refund")
    end
  end

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

  describe "#value" do
    describe "always stores a negative #value" do
      context "when given a positive value" do
        let(:refund) { create(:refund, value: "100.01") }

        it "stores a negative value" do
          expect(refund.reload.value.to_s).to eq("-100.01")
        end
      end

      context "when given a negative value" do
        let(:refund) { create(:refund, value: "-100.01") }

        it "stores a negative value" do
          expect(refund.reload.value.to_s).to eq("-100.01")
        end
      end
    end

    context "when value is missing" do
      let(:refund) { build(:refund, value: nil) }

      it "is invalid" do
        refund.valid?

        expect(refund.errors.messages[:value])
          .to eq(["Enter a refund amount", "Refund amount must be a valid number"])
      end
    end

    context "when value is not a number" do
      let(:refund) { build(:refund, value: "rubbish") }

      it "is invalid" do
        refund.valid?

        expect(refund.errors.messages[:value])
          .to eq(["Enter a refund amount", "Refund amount must be a valid number"])
      end
    end
  end
end
